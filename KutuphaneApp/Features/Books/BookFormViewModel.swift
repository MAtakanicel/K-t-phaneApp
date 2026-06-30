import Foundation

@MainActor
@Observable
final class BookFormViewModel {
    var title: String = ""
    var author: String = ""
    var isbn: String = ""
    var category: String = ""
    var shelfLocation: String = ""
    var coverImageURL: String?
    var isSaving: Bool = false
    var errorMessage: String? = nil

    // Faz 7: Google Books otomatik doldurma durumu
    var isLookingUp: Bool = false
    var lookupHint: LookupHint? = nil

    enum LookupHint: Equatable {
        case filled              // §5.4 — "✓ Google Books'tan dolduruldu"
        case notFound            // D4 — sonuç yok
        case networkError        // D4 — ağ/timeout
    }

    let editingBook: Book?
    let bookRepo: any BookRepository
    let lookupService: any BookLookupService

    private var lookupTask: Task<Void, Never>? = nil

    init(editingBook: Book? = nil,
         bookRepo: any BookRepository,
         lookupService: any BookLookupService = GoogleBooksLookupService()) {
        self.editingBook = editingBook
        self.bookRepo = bookRepo
        self.lookupService = lookupService
        if let book = editingBook {
            title        = book.title
            author       = book.author
            isbn         = book.isbn ?? ""
            category     = book.category ?? ""
            shelfLocation = book.shelfLocation ?? ""
            coverImageURL = book.coverImageURL
        }
    }

    var isEditing: Bool { editingBook != nil }
    var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty &&
                        !author.trimmingCharacters(in: .whitespaces).isEmpty }

    // MARK: - Google Books lookup

    func lookupISBN() {
        let trimmed = isbn.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 8 else { return }

        lookupTask?.cancel()
        lookupHint = nil
        isLookingUp = true

        lookupTask = Task { [weak self, lookupService] in
            defer { Task { @MainActor in self?.isLookingUp = false } }
            do {
                let meta = try await lookupService.lookup(isbn: trimmed)
                guard !Task.isCancelled else { return }
                await MainActor.run { self?.apply(meta) }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run { self?.lookupHint = .networkError }
            }
        }
    }

    // Boş olan alanları doldur; kullanıcı yazdıysa üstüne yazma.
    private func apply(_ meta: BookMetadata?) {
        guard let meta else {
            lookupHint = .notFound
            return
        }
        var filledAny = false
        if title.trimmingCharacters(in: .whitespaces).isEmpty, !meta.title.isEmpty {
            title = meta.title
            filledAny = true
        }
        if author.trimmingCharacters(in: .whitespaces).isEmpty, !meta.authors.isEmpty {
            author = meta.authorsJoined
            filledAny = true
        }
        if category.trimmingCharacters(in: .whitespaces).isEmpty, let cat = meta.category {
            category = cat
            filledAny = true
        }
        if coverImageURL == nil, let cover = meta.coverImageURL {
            coverImageURL = cover
            filledAny = true
        }
        lookupHint = filledAny ? .filled : .notFound
    }

    // MARK: - Kaydet / Sil

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
            updated.coverImageURL = coverImageURL
            updated.updatedAt     = Date()
            try await bookRepo.updateBook(updated)
        } else {
            let newBook = Book(
                title: title, author: author,
                isbn: isbn.isEmpty ? nil : isbn,
                category: category.isEmpty ? nil : category,
                shelfLocation: shelfLocation.isEmpty ? nil : shelfLocation,
                coverImageURL: coverImageURL,
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
