import Foundation
import FirebaseFirestore

// MARK: - Hata türleri

enum LendingError: Error, LocalizedError {
    case bookNotAvailable
    case memberLimitReached
    case bookNotFound
    case memberNotFound

    var errorDescription: String? {
        switch self {
        case .bookNotAvailable:    return "Bu kitap şu an ödünçte, verilemez."
        case .memberLimitReached:  return "Bu üyede 3 kitap var, önce iade gerekli."
        case .bookNotFound:        return "Kitap bulunamadı."
        case .memberNotFound:      return "Üye bulunamadı."
        }
    }
}

// MARK: - Protokol

protocol LendingService {
    /// `settings` çağrı anındaki Ayarlar snapshot'ı (limit + süre).
    /// D6: Hesaplar tek kaynaktan akar; servis kendi sabitlerini taşımaz.
    func borrow(bookId: String, memberId: String, settings: LendingSettings) async throws
    func returnBook(bookId: String) async throws
}

// MARK: - Firestore implementasyonu (Yaklaşım A — Teknik Tasarım §3.2)

final class FirestoreLendingService: LendingService {
    private let db = Firestore.firestore()
    private let loanRepo: any LoanRepository

    init(loanRepo: any LoanRepository = FirestoreLoanRepository()) {
        self.loanRepo = loanRepo
    }

    func borrow(bookId: String, memberId: String, settings: LendingSettings) async throws {
        // Adım 1: Üye limiti kontrolü (transaction dışında — tek görevli için güvenli)
        let active = try await loanRepo.activeLoans(forMember: memberId)
        guard active.count < settings.loanLimit else { throw LendingError.memberLimitReached }

        // Adım 2: Transaction — kitap müsaitliği + atomik yazma + snapshot alanları
        let bookRef   = db.collection("books").document(bookId)
        let memberRef = db.collection("members").document(memberId)
        let loanRef   = db.collection("loans").document()
        let loanId    = loanRef.documentID
        let now       = Date()
        let dueDate   = settings.dueDate(from: now)

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            db.runTransaction({ transaction, errPtr -> Any? in
                let bookSnap: DocumentSnapshot
                let memberSnap: DocumentSnapshot
                do {
                    // Tüm okumalar yazımlardan ÖNCE — Firestore transaction kuralı.
                    bookSnap = try transaction.getDocument(bookRef)
                    memberSnap = try transaction.getDocument(memberRef)
                } catch {
                    errPtr?.pointee = error as NSError; return nil
                }

                guard bookSnap.exists else {
                    errPtr?.pointee = LendingError.bookNotFound as NSError; return nil
                }
                guard (bookSnap.data()?["status"] as? String) == BookStatus.available.rawValue else {
                    errPtr?.pointee = LendingError.bookNotAvailable as NSError; return nil
                }
                guard memberSnap.exists else {
                    errPtr?.pointee = LendingError.memberNotFound as NSError; return nil
                }

                let bookTitle  = (bookSnap.data()?["title"] as? String) ?? ""
                let memberName = (memberSnap.data()?["fullName"] as? String) ?? ""

                transaction.updateData([
                    "status": BookStatus.borrowed.rawValue,
                    "currentBorrowerId": memberId,
                    "currentLoanId": loanId,
                    "borrowedDate": Timestamp(date: now),
                    "updatedAt": Timestamp(date: now)
                ], forDocument: bookRef)

                transaction.setData([
                    "bookId": bookId,
                    "memberId": memberId,
                    "borrowDate": Timestamp(date: now),
                    "dueDate": Timestamp(date: dueDate),
                    "returnDate": NSNull(),
                    "bookTitleSnapshot": bookTitle,
                    "memberNameSnapshot": memberName
                ], forDocument: loanRef)

                return nil
            }, completion: { _, error in
                if let error { cont.resume(throwing: error) }
                else { cont.resume() }
            })
        }
    }

    func returnBook(bookId: String) async throws {
        let bookRef = db.collection("books").document(bookId)

        // Aktif loan'u bul
        let snap = try await db.collection("loans")
            .whereField("bookId", isEqualTo: bookId)
            .whereField("returnDate", isEqualTo: NSNull())
            .limit(to: 1)
            .getDocuments()
        guard let loanDoc = snap.documents.first else { throw LendingError.bookNotFound }
        let loanRef = db.collection("loans").document(loanDoc.documentID)
        let now = Date()

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            db.runTransaction({ transaction, errPtr -> Any? in
                transaction.updateData([
                    "status": BookStatus.available.rawValue,
                    "currentBorrowerId": NSNull(),
                    "currentLoanId": NSNull(),
                    "borrowedDate": NSNull(),
                    "updatedAt": Timestamp(date: now)
                ], forDocument: bookRef)

                transaction.updateData(["returnDate": Timestamp(date: now)],
                                       forDocument: loanRef)
                return nil
            }, completion: { _, error in
                if let error { cont.resume(throwing: error) }
                else { cont.resume() }
            })
        }
    }
}

// MARK: - Mock implementasyonu

@MainActor
final class MockLendingService: LendingService {
    let bookRepo: any BookRepository
    let memberRepo: any MemberRepository
    let loanRepo: MockLoanRepository

    init(bookRepo: any BookRepository = MockBookRepository(),
         memberRepo: any MemberRepository = MockMemberRepository(),
         loanRepo: MockLoanRepository = MockLoanRepository()) {
        self.bookRepo = bookRepo
        self.memberRepo = memberRepo
        self.loanRepo = loanRepo
    }

    func borrow(bookId: String, memberId: String, settings: LendingSettings) async throws {
        let active = try await loanRepo.activeLoans(forMember: memberId)
        guard active.count < settings.loanLimit else { throw LendingError.memberLimitReached }

        guard var book = try? await bookRepo.fetchBook(id: bookId) else {
            throw LendingError.bookNotFound
        }
        guard book.status == .available else { throw LendingError.bookNotAvailable }
        let member = try? await memberRepo.fetchMember(id: memberId)

        let now = Date()
        let dueDate = settings.dueDate(from: now)
        let loanId = UUID().uuidString

        book.status = .borrowed
        book.currentBorrowerId = memberId
        book.currentLoanId = loanId
        book.borrowedDate = now
        book.updatedAt = now
        try await bookRepo.updateBook(book)

        var loan = Loan(bookId: bookId, memberId: memberId,
                        borrowDate: now, dueDate: dueDate)
        loan.id = loanId
        loan.bookTitleSnapshot = book.title
        loan.memberNameSnapshot = member?.fullName
        loanRepo.addLoan(loan)
    }

    func returnBook(bookId: String) async throws {
        guard var book = try? await bookRepo.fetchBook(id: bookId) else {
            throw LendingError.bookNotFound
        }
        let loanId = book.currentLoanId
        let now = Date()
        book.status = .available
        book.currentBorrowerId = nil
        book.currentLoanId = nil
        book.borrowedDate = nil
        book.updatedAt = now
        try await bookRepo.updateBook(book)
        if let loanId { loanRepo.returnLoan(id: loanId) }
    }
}
