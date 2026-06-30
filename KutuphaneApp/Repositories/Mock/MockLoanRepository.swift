import Foundation

final class MockLoanRepository: LoanRepository {
    private(set) var loans: [Loan]

    init(loans: [Loan] = MockData.loans) {
        self.loans = loans
    }

    func observeLoans() -> AsyncStream<[Loan]> {
        AsyncStream { continuation in
            continuation.yield(loans)
            continuation.finish()
        }
    }

    func activeLoans(forMember memberId: String) async throws -> [Loan] {
        loans.filter { $0.memberId == memberId && $0.isActive }
    }

    func loanHistory(forMember memberId: String) async throws -> [Loan] {
        loans
            .filter { $0.memberId == memberId }
            .sorted { $0.borrowDate > $1.borrowDate }
    }

    func loanHistory(forBook bookId: String) async throws -> [Loan] {
        loans
            .filter { $0.bookId == bookId }
            .sorted { $0.borrowDate > $1.borrowDate }
    }

    // Test yardımcısı: ödünç ekle / iade et
    func addLoan(_ loan: Loan) {
        var l = loan
        if l.id == nil { l.id = UUID().uuidString }
        loans.append(l)
    }

    func returnLoan(id: String) {
        guard let idx = loans.firstIndex(where: { $0.id == id }) else { return }
        loans[idx].returnDate = Date()
    }
}
