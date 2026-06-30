import Foundation
import FirebaseFirestore

// MARK: - Protokol

protocol MemberRepository {
    func observeMembers() -> AsyncStream<[Member]>
    func fetchMember(id: String) async throws -> Member
    func findByNumber(_ number: String) async throws -> Member?
    func addMember(_ member: Member) async throws
    func updateMember(_ member: Member) async throws
    func deleteMember(id: String) async throws
}

// MARK: - Firestore implementasyonu

final class FirestoreMemberRepository: MemberRepository {
    private let collection = Firestore.firestore().collection("members")

    func observeMembers() -> AsyncStream<[Member]> {
        AsyncStream { continuation in
            let listener = Firestore.firestore().collection("members")
                .addSnapshotListener { snapshot, _ in
                    let members = snapshot?.documents.compactMap {
                        try? $0.data(as: Member.self)
                    } ?? []
                    continuation.yield(members)
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func fetchMember(id: String) async throws -> Member {
        try await collection.document(id).getDocument(as: Member.self)
    }

    func findByNumber(_ number: String) async throws -> Member? {
        let snapshot = try await collection
            .whereField("memberNumber", isEqualTo: number)
            .limit(to: 1)
            .getDocuments()
        return try snapshot.documents.first.map { try $0.data(as: Member.self) }
    }

    func addMember(_ member: Member) async throws {
        _ = try collection.addDocument(from: member)
    }

    func updateMember(_ member: Member) async throws {
        guard let id = member.id else { throw RepositoryError.invalidData }
        try collection.document(id).setData(from: member, merge: false)
    }

    func deleteMember(id: String) async throws {
        try await collection.document(id).delete()
    }
}
