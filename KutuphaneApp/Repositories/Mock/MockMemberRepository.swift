import Foundation

final class MockMemberRepository: MemberRepository {
    private(set) var members: [Member]
    private var continuation: AsyncStream<[Member]>.Continuation?

    init(members: [Member] = MockData.members) {
        self.members = members
    }

    func observeMembers() -> AsyncStream<[Member]> {
        AsyncStream { [weak self] cont in
            guard let self else { return }
            self.continuation = cont
            cont.yield(self.members)
        }
    }

    func fetchMember(id: String) async throws -> Member {
        guard let member = members.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        return member
    }

    func findByNumber(_ number: String) async throws -> Member? {
        members.first { $0.memberNumber == number }
    }

    func addMember(_ member: Member) async throws {
        var newMember = member
        if newMember.id == nil { newMember.id = UUID().uuidString }
        members.append(newMember)
        continuation?.yield(members)
    }

    func updateMember(_ member: Member) async throws {
        guard let idx = members.firstIndex(where: { $0.id == member.id }) else {
            throw RepositoryError.notFound
        }
        members[idx] = member
        continuation?.yield(members)
    }

    func deleteMember(id: String) async throws {
        members.removeAll { $0.id == id }
        continuation?.yield(members)
    }
}
