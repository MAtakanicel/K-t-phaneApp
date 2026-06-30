import Foundation

@MainActor
@Observable
final class BooksViewModel {
    var books: [Book] = []
    var searchText: String = ""
    var filterIndex: Int = 0    // 0=Hepsi 1=Rafta 2=Ödünçte
    var isLoading: Bool = true
    var errorMessage: String? = nil
    var showingAddForm: Bool = false

    let bookRepo: any BookRepository

    init(bookRepo: any BookRepository) {
        self.bookRepo = bookRepo
    }

    // MARK: - Türetilmiş liste (D6: filtre/arama runtime'da hesaplanır)

    var filteredBooks: [Book] {
        var result = books
        switch filterIndex {
        case 1: result = result.filter { $0.status == .available }
        case 2: result = result.filter { $0.status == .borrowed }
        default: break
        }
        guard !searchText.isEmpty else { return result }
        let q = searchText.lowercased()
        return result.filter {
            $0.title.lowercased().contains(q) ||
            $0.author.lowercased().contains(q) ||
            ($0.isbn?.lowercased().contains(q) ?? false)
        }
    }

    // D6: gecikme günü runtime'da hesaplanır, modele yazılmaz
    func overdueDays(for book: Book) -> Int? {
        guard book.status == .borrowed,
              let borrowedDate = book.borrowedDate else { return nil }
        let due = Calendar.current.date(byAdding: .day, value: 15, to: borrowedDate) ?? borrowedDate
        let days = Calendar.current.dateComponents([.day], from: due, to: .now).day ?? 0
        return days > 0 ? days : nil
    }

    // MARK: - Gözlem (Firestore snapshot listener canlı yayın)
    // SwiftUI .task'ı doğrudan for-await yapar; cancellation otomatik yönetilir.

    func observe() async {
        isLoading = true
        errorMessage = nil
        for await newBooks in bookRepo.observeBooks() {
            books = newBooks
            isLoading = false
        }
    }
}
