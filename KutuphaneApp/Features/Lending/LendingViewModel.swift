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

    // MARK: - Barkod ile üye bulma

    func handleScannedMemberCode(_ code: String) async {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let local = members.first(where: { $0.memberNumber == trimmed })
        do {
            let member: Member?
            if let local {
                member = local
            } else {
                let remote = try await memberRepo.findByNumber(trimmed)
                if let remote, !members.contains(where: { $0.id == remote.id }) {
                    members.append(remote)
                }
                member = remote
            }
            guard let member else {
                errorMessage = "Bu numarayla bir üye bulunamadı: \(trimmed)"
                return
            }
            if let id = member.id, loanCounts[id] == nil {
                let count = (try? await loanRepo.activeLoans(forMember: id).count) ?? 0
                loanCounts[id] = count
            }
            selectMember(member)
        } catch {
            errorMessage = "Üye okunamadı: \(error.localizedDescription)"
        }
    }

    // MARK: - Üye seçimi

    func selectMember(_ member: Member) {
        guard let id = member.id else { return }
        let count = loanCounts[id] ?? 0
        if count >= 3 {
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

    var dueDate: Date {
        Calendar.current.date(byAdding: .day, value: 15, to: .now) ?? .now
    }

    func confirm() async throws {
        guard case .confirming(let member) = state,
              let memberId = member.id,
              let bookId = book.id else { return }
        isConfirming = true
        defer { isConfirming = false }
        try await lendingService.borrow(bookId: bookId, memberId: memberId)
    }
}
