import Foundation

// §7.1 — Ödünç ver sheet'inin 3 durumu
enum LendingState {
    case selectingMember
    case limitReached(member: Member)
    case confirming(member: Member)
}

@MainActor
@Observable
final class LendingViewModel: Identifiable {
    let id = UUID()

    var state: LendingState = .selectingMember
    var searchText: String = ""
    var members: [Member] = []
    var loanCounts: [String: Int] = [:]
    var isLoadingMembers: Bool = true
    var isConfirming: Bool = false
    var errorMessage: String? = nil

    let book: Book
    private let lendingService: any LendingService
    private let memberRepo: any MemberRepository
    private let loanRepo: any LoanRepository

    init(book: Book,
         lendingService: any LendingService,
         memberRepo: any MemberRepository,
         loanRepo: any LoanRepository) {
        self.book = book
        self.lendingService = lendingService
        self.memberRepo = memberRepo
        self.loanRepo = loanRepo
    }

    var filteredMembers: [Member] {
        guard !searchText.isEmpty else { return members }
        let q = searchText.lowercased()
        return members.filter {
            $0.fullName.lowercased().contains(q) || $0.memberNumber.contains(q)
        }
    }

    // MARK: - Yükleme

    func loadMembers() async {
        isLoadingMembers = true
        defer { isLoadingMembers = false }
        var iterator = memberRepo.observeMembers().makeAsyncIterator()
        let ms = await iterator.next() ?? []
        members = ms
        Task { await loadLoanCounts(for: ms) }
    }

    private func loadLoanCounts(for ms: [Member]) async {
        // Sıralı sorgular — @MainActor + withTaskGroup deadlock riskini önler
        // Her üye ayrı ayrı ele alınır; biri patlarsa liste bloklanmaz
        for m in ms {
            guard let id = m.id else { continue }
            do {
                let count = try await loanRepo.activeLoans(forMember: id).count
                loanCounts[id] = count
            } catch {
                print("[LendingViewModel] Loan count error for member \(id): \(error)")
                loanCounts[id] = 0
            }
        }
    }

    // MARK: - Üye seçimi

    func selectMember(_ member: Member) {
        guard let id = member.id else { return }
        let count = loanCounts[id] ?? 0
        if count >= LendingSettings.current.loanLimit {
            state = .limitReached(member: member)
        } else {
            state = .confirming(member: member)
        }
    }

    func resetToSelecting() {
        state = .selectingMember
        searchText = ""
    }

    // MARK: - Onayla

    // D6: Faz 8 — iade tarihi Ayarlar.loanDurationDays üzerinden tek kaynaktan türetilir.
    var dueDate: Date {
        LendingSettings.current.dueDate(from: .now)
    }

    func confirm() async throws {
        guard case .confirming(let member) = state,
              let memberId = member.id,
              let bookId = book.id else { return }
        isConfirming = true
        defer { isConfirming = false }
        try await lendingService.borrow(bookId: bookId,
                                        memberId: memberId,
                                        settings: LendingSettings.current)
    }
}
