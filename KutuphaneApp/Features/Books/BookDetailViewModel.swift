import Foundation

@MainActor
@Observable
final class BookDetailViewModel {
    var book: Book
    var borrowerName: String? = nil
    var loanHistory: [Loan] = []
    var isLoadingHistory: Bool = false
    var actionError: String? = nil
    // Eski kayıtlar için memberNameSnapshot boşsa memberId → fullName fallback
    var memberNamesById: [String: String] = [:]

    let bookRepo: any BookRepository
    private let loanRepo: any LoanRepository
    private let memberRepo: (any MemberRepository)?
    let lendingService: any LendingService

    init(book: Book,
         bookRepo: any BookRepository,
         loanRepo: any LoanRepository,
         memberRepo: (any MemberRepository)? = nil,
         lendingService: any LendingService = FirestoreLendingService()) {
        self.book = book
        self.bookRepo = bookRepo
        self.loanRepo = loanRepo
        self.memberRepo = memberRepo
        self.lendingService = lendingService
    }

    // D6: gecikme günü runtime türetilir
    var overdueDays: Int? {
        guard book.status == .borrowed,
              let borrowed = book.borrowedDate else { return nil }
        let due = Calendar.current.date(byAdding: .day, value: 15, to: borrowed) ?? borrowed
        let days = Calendar.current.dateComponents([.day], from: due, to: .now).day ?? 0
        return days > 0 ? days : nil
    }

    var badgeStatus: BookBadgeStatus {
        switch book.status {
        case .available: return .available
        case .borrowed:
            if let d = overdueDays { return .overdue(days: d) }
            return .borrowed
        }
    }

    func load() async {
        // Önce kitabı tazele — ödünç/iade sonrası status, currentBorrowerId vs. güncellensin.
        if let id = book.id, let fresh = try? await bookRepo.fetchBook(id: id) {
            book = fresh
        }

        if let borrowerId = book.currentBorrowerId, let memberRepo {
            borrowerName = (try? await memberRepo.fetchMember(id: borrowerId))?.fullName
        } else {
            borrowerName = nil
        }
        guard let id = book.id else { return }
        isLoadingHistory = true
        let history = (try? await loanRepo.loanHistory(forBook: id)) ?? []
        loanHistory = history

        // Snapshot boş olan eski kayıtlar için memberId ile üye adı doldur (fallback)
        if let memberRepo {
            let missingIds = Set(history
                .filter { ($0.memberNameSnapshot ?? "").isEmpty }
                .map { $0.memberId })
            for mid in missingIds where memberNamesById[mid] == nil {
                if let m = try? await memberRepo.fetchMember(id: mid) {
                    memberNamesById[mid] = m.fullName
                }
            }
        }
        isLoadingHistory = false
    }

    /// View tarafı için: önce snapshot, boşsa fallback map, en sonda "—".
    func displayName(for loan: Loan) -> String {
        if let snap = loan.memberNameSnapshot, !snap.isEmpty { return snap }
        if let mapped = memberNamesById[loan.memberId] { return mapped }
        return "—"
    }

    func returnBook() async throws {
        guard let id = book.id else { throw RepositoryError.invalidData }
        try await lendingService.returnBook(bookId: id)
    }

    func delete() async throws {
        guard let id = book.id else { throw RepositoryError.invalidData }
        try await bookRepo.deleteBook(id: id)
    }
}
