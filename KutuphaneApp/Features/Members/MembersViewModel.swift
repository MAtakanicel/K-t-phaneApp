import Foundation

@MainActor
@Observable
final class MembersViewModel {
    var members: [Member] = []
    var loanCounts: [String: Int] = [:]    // memberId → aktif loan sayısı (D6)
    var searchText: String = ""
    var isLoading: Bool = true
    var errorMessage: String? = nil
    var showingAddForm: Bool = false

    let memberRepo: any MemberRepository
    private let loanRepo: any LoanRepository

    init(memberRepo: any MemberRepository, loanRepo: any LoanRepository) {
        self.memberRepo = memberRepo
        self.loanRepo = loanRepo
    }

    // MARK: - Türetilmiş (D6)

    var filteredMembers: [Member] {
        guard !searchText.isEmpty else { return members }
        let q = searchText.lowercased()
        return members.filter {
            $0.fullName.lowercased().contains(q) ||
            $0.memberNumber.lowercased().contains(q)
        }
    }

    func loanCount(for member: Member) -> Int {
        guard let id = member.id else { return 0 }
        return loanCounts[id] ?? 0
    }

    // MARK: - Gözlem (Firestore snapshot listener canlı yayın)
    // SwiftUI .task'ı içinde members + loans paralel dinlenir.

    func observe() async {
        isLoading = true
        errorMessage = nil
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in await self?.observeMembersStream() }
            group.addTask { [weak self] in await self?.observeLoansStream() }
        }
    }

    private func observeMembersStream() async {
        for await newMembers in memberRepo.observeMembers() {
            members = newMembers
            isLoading = false
        }
    }

    private func observeLoansStream() async {
        for await allLoans in loanRepo.observeLoans() {
            var counts: [String: Int] = [:]
            for loan in allLoans where loan.isActive {
                counts[loan.memberId, default: 0] += 1
            }
            loanCounts = counts
        }
    }
}
