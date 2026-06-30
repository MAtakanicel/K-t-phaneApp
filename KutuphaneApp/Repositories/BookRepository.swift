import Foundation
import FirebaseFirestore

// MARK: - Hata türleri

enum RepositoryError: Error, LocalizedError {
    case notFound
    case invalidData

    var errorDescription: String? {
        switch self {
        case .notFound:    return "Kayıt bulunamadı."
        case .invalidData: return "Veri okunamadı."
        }
    }
}

// MARK: - Protokol

protocol BookRepository {
    /// Canlı dinleyici; snapshot her değiştiğinde yeni dizi yayınlar.
    func observeBooks() -> AsyncStream<[Book]>
    func fetchBook(id: String) async throws -> Book
    func addBook(_ book: Book) async throws
    func updateBook(_ book: Book) async throws
    func deleteBook(id: String) async throws
    func findByISBN(_ isbn: String) async throws -> Book?
}

// MARK: - Firestore implementasyonu

final class FirestoreBookRepository: BookRepository {
    private let collection = Firestore.firestore().collection("books")

    func observeBooks() -> AsyncStream<[Book]> {
        AsyncStream { continuation in
            let listener = Firestore.firestore().collection("books")
                .addSnapshotListener { snapshot, _ in
                    let books = snapshot?.documents.compactMap {
                        try? $0.data(as: Book.self)
                    } ?? []
                    continuation.yield(books)
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func fetchBook(id: String) async throws -> Book {
        try await collection.document(id).getDocument(as: Book.self)
    }

    func addBook(_ book: Book) async throws {
        _ = try collection.addDocument(from: book)
    }

    func updateBook(_ book: Book) async throws {
        guard let id = book.id else { throw RepositoryError.invalidData }
        try collection.document(id).setData(from: book, merge: false)
    }

    func deleteBook(id: String) async throws {
        try await collection.document(id).delete()
    }

    func findByISBN(_ isbn: String) async throws -> Book? {
        let snapshot = try await collection
            .whereField("isbn", isEqualTo: isbn)
            .limit(to: 1)
            .getDocuments()
        return try snapshot.documents.first.map { try $0.data(as: Book.self) }
    }
}
