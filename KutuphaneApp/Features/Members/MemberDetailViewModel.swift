import Foundation

// Aktif ödünçteki kitap + loan birlikte taşınır; türetilmiş alan yok (D6)
struct LoanWithBook: Identifiable {
    let loan: Loan
    let book: Book
    var id: String { loan.id ?? book.id ?? UUID().uuidString }
}

enum MemberDeleteError: Error, LocalizedError {
    case hasActiveLoans(count: Int, name: String)

    var errorDescription: String? {
        switch self {
        case let .hasActiveLoans(count, name):
            return "\(name) üzerinde \(count) kitap var. Önce iade alınmalı."
        }
    }
}

@MainActor
@Observable
final class MemberDetailViewModel {
    var member: Member
    var activeItems: [LoanWithBook] = []
    var isLoading: Bool = false
    var returnError: String? = nil

    let memberRepo: any MemberRepository
    let loanRepo: any LoanRepository
    let bookRepo: any BookRepository
    private let lendingService: any LendingService

    init(member: Member,
         memberRepo: any MemberRepository,
         loanRepo: any LoanRepository,
         bookRepo: any BookRepository,
         lendingService: any LendingService = FirestoreLendingService()) {
        self.member = member
        self.memberRepo = memberRepo
        self.loanRepo = loanRepo
        self.bookRepo = bookRepo
        self.lendingService = lendingService
    }

    // MARK: - Türetilmiş (D6)

    var loanCount: Int { activeItems.count }
    var canDelete: Bool { activeItems.isEmpty }

    // Gecikme günü loan.dueDate'ten runtime'da hesaplanır
    func overdueDays(for loan: Loan) -> Int? {
        guard let due = loan.dueDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: due, to: .now).day ?? 0
        return days > 0 ? days : nil
    }

    // MARK: - Yükleme

    func load() async {
        guard let id = member.id else { return }
        isLoading = true
        let loans = (try? await loanRepo.activeLoans(forMember: id)) ?? []
        var items: [LoanWithBook] = []
        for loan in loans {
            if let book = try? await bookRepo.fetchBook(id: loan.bookId) {
                items.append(LoanWithBook(loan: loan, book: book))
            }
        }
        activeItems = items
        isLoading = false
    }

    // MARK: - İade

    func returnBook(bookId: String) async throws {
        try await lendingService.returnBook(bookId: bookId)
        await load()
    }

    // MARK: - Silme

    func delete() async throws {
        if !canDelete {
            throw MemberDeleteError.hasActiveLoans(count: loanCount,
                                                   name: member.fullName)
        }
        guard let id = member.id else { throw RepositoryError.invalidData }
        try await memberRepo.deleteMember(id: id)
    }
}
