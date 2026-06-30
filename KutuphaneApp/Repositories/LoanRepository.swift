import Foundation
import FirebaseFirestore

// MARK: - Protokol

protocol LoanRepository {
    /// Tüm loans koleksiyonunu canlı dinler — Üye listesi loan sayılarını güncel tutmak için.
    func observeLoans() -> AsyncStream<[Loan]>
    /// Üyenin aktif (iade edilmemiş) ödünçleri — limit kontrolünde kullanılır.
    func activeLoans(forMember memberId: String) async throws -> [Loan]
    func loanHistory(forMember memberId: String) async throws -> [Loan]
    func loanHistory(forBook bookId: String) async throws -> [Loan]
}

// MARK: - Firestore implementasyonu

final class FirestoreLoanRepository: LoanRepository {
    private let collection = Firestore.firestore().collection("loans")

    func observeLoans() -> AsyncStream<[Loan]> {
        AsyncStream { continuation in
            let listener = Firestore.firestore().collection("loans")
                .addSnapshotListener { snapshot, _ in
                    let loans = snapshot?.documents.compactMap {
                        try? $0.data(as: Loan.self)
                    } ?? []
                    continuation.yield(loans)
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func activeLoans(forMember memberId: String) async throws -> [Loan] {
        // Üye başına maksimum 3 aktif loan; client-side filtre yeterli.
        // Composite index gerekmez; Firestore konsolundan link gelirse oluştur.
        let snapshot = try await collection
            .whereField("memberId", isEqualTo: memberId)
            .getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: Loan.self) }
            .filter { $0.isActive }
    }

    func loanHistory(forMember memberId: String) async throws -> [Loan] {
        let snapshot = try await collection
            .whereField("memberId", isEqualTo: memberId)
            .order(by: "borrowDate", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Loan.self) }
    }

    func loanHistory(forBook bookId: String) async throws -> [Loan] {
        let snapshot = try await collection
            .whereField("bookId", isEqualTo: bookId)
            .order(by: "borrowDate", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Loan.self) }
    }
}
