import Foundation

final class MockBookRepository: BookRepository {
    private(set) var books: [Book]
    private var continuation: AsyncStream<[Book]>.Continuation?

    init(books: [Book] = MockData.books) {
        self.books = books
    }

    func observeBooks() -> AsyncStream<[Book]> {
        AsyncStream { [weak self] cont in
            guard let self else { return }
            self.continuation = cont
            cont.yield(self.books)
        }
    }

    func fetchAllBooks() async throws -> [Book] { books }

    func fetchBook(id: String) async throws -> Book {
        guard let book = books.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        return book
    }

    func addBook(_ book: Book) async throws {
        var newBook = book
        if newBook.id == nil { newBook.id = UUID().uuidString }
        books.append(newBook)
        continuation?.yield(books)
    }

    func updateBook(_ book: Book) async throws {
        guard let idx = books.firstIndex(where: { $0.id == book.id }) else {
            throw RepositoryError.notFound
        }
        books[idx] = book
        continuation?.yield(books)
    }

    func deleteBook(id: String) async throws {
        books.removeAll { $0.id == id }
        continuation?.yield(books)
    }

    func findByISBN(_ isbn: String) async throws -> Book? {
        books.first { $0.isbn == isbn }
    }
}
