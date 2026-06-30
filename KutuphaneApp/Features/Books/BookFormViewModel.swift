import Foundation

@MainActor
@Observable
final class BookFormViewModel {
    var title: String = ""
    var author: String = ""
    var isbn: String = ""
    var category: String = ""
    var shelfLocation: String = ""
    var isSaving: Bool = false
    var errorMessage: String? = nil

    let editingBook: Book?
    let bookRepo: any BookRepository

    init(editingBook: Book? = nil, bookRepo: any BookRepository) {
        self.editingBook = editingBook
        self.bookRepo = bookRepo
        if let book = editingBook {
            title        = book.title
            author       = book.author
            isbn         = book.isbn ?? ""
            category     = book.category ?? ""
            shelfLocation = book.shelfLocation ?? ""
        }
    }

    var isEditing: Bool { editingBook != nil }
    var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty &&
                        !author.trimmingCharacters(in: .whitespaces).isEmpty }

    func save() async throws {
        isSaving = true
        defer { isSaving = false }
        if let existing = editingBook {
            var updated = existing
            updated.title         = title
            updated.author        = author
            updated.isbn          = isbn.isEmpty ? nil : isbn
            updated.category      = category.isEmpty ? nil : category
            updated.shelfLocation = shelfLocation.isEmpty ? nil : shelfLocation
            updated.updatedAt     = Date()
            try await bookRepo.updateBook(updated)
        } else {
            let newBook = Book(
                title: title, author: author,
                isbn: isbn.isEmpty ? nil : isbn,
                category: category.isEmpty ? nil : category,
                shelfLocation: shelfLocation.isEmpty ? nil : shelfLocation,
                status: .available,
                createdAt: Date(), updatedAt: Date()
            )
            try await bookRepo.addBook(newBook)
        }
    }

    func delete() async throws {
        guard let id = editingBook?.id else { throw RepositoryError.invalidData }
        try await bookRepo.deleteBook(id: id)
    }
}
