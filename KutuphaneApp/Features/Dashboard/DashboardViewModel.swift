import Foundation

// Özet ekranında gecikmiş satır olarak gösterilen tek bir kayıt.
// D6: overdueDays ve memberName runtime'da türetilir; modele yazılmaz.
struct OverdueItem: Identifiable {
    let book: Book
    let memberId: String
    let memberName: String
    let borrowDate: Date
    let overdueDays: Int
    var id: String { book.id ?? UUID().uuidString }
}

@MainActor
@Observable
final class DashboardViewModel {
    var totalBooks: Int = 0
    var availableCount: Int = 0
    var borrowedCount: Int = 0
    var overdueItems: [OverdueItem] = []
    var isLoading: Bool = true
    var errorMessage: String? = nil

    var books: [Book] = []
    var members: [Member] = []
    var loans: [Loan] = []

    let bookRepo: any BookRepository
    private let memberRepo: any MemberRepository
    private let loanRepo: any LoanRepository

    init(bookRepo: any BookRepository,
         memberRepo: any MemberRepository,
         loanRepo: any LoanRepository) {
        self.bookRepo = bookRepo
        self.memberRepo = memberRepo
        self.loanRepo = loanRepo
    }

    var overdueCount: Int { overdueItems.count }

    // MARK: - Gözlem
    // Books + members + loans paralel dinlenir; her stream geldiğinde sayaçlar
    // ve gecikmiş liste tek kaynaktan (LendingSettings.current) yeniden hesaplanır.

    func observe() async {
        isLoading = true
        errorMessage = nil
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in await self?.observeBooksStream() }
            group.addTask { [weak self] in await self?.observeMembersStream() }
            group.addTask { [weak self] in await self?.observeLoansStream() }
        }
    }

    private func observeBooksStream() async {
        for await fresh in bookRepo.observeBooks() {
            books = fresh
            recompute()
            isLoading = false
        }
    }

    private func observeMembersStream() async {
        for await fresh in memberRepo.observeMembers() {
            members = fresh
            recompute()
        }
    }

    private func observeLoansStream() async {
        for await fresh in loanRepo.observeLoans() {
            loans = fresh
            recompute()
        }
    }

    // MARK: - Pull-to-refresh
    // Tek seferlik fetch — books + members + loans paralel, sonrasında tek `recompute()`.

    func refresh() async {
        errorMessage = nil
        do {
            async let booksTask = bookRepo.fetchAllBooks()
            async let membersTask = memberRepo.fetchAllMembers()
            async let loansTask = loanRepo.fetchAllLoans()
            let (b, m, l) = try await (booksTask, membersTask, loansTask)
            books = b
            members = m
            loans = l
            recompute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Türetim (D6)

    func recompute() {
        totalBooks = books.count
        availableCount = books.filter { $0.status == .available }.count
        borrowedCount = books.filter { $0.status == .borrowed }.count

        let settings = LendingSettings.current
        let memberById = Dictionary(uniqueKeysWithValues:
            members.compactMap { m -> (String, Member)? in
                guard let id = m.id else { return nil }
                return (id, m)
            })
        let bookById = Dictionary(uniqueKeysWithValues:
            books.compactMap { b -> (String, Book)? in
                guard let id = b.id else { return nil }
                return (id, b)
            })

        var items: [OverdueItem] = []
        for loan in loans where loan.isActive {
            guard let days = settings.overdueDays(from: loan.borrowDate),
                  let book = bookById[loan.bookId] else { continue }
            let memberName = memberById[loan.memberId]?.fullName
                ?? loan.memberNameSnapshot
                ?? "—"
            items.append(OverdueItem(
                book: book,
                memberId: loan.memberId,
                memberName: memberName,
                borrowDate: loan.borrowDate,
                overdueDays: days
            ))
        }
        items.sort { $0.overdueDays > $1.overdueDays }
        overdueItems = items
    }
}
