import Foundation

@MainActor
@Observable
final class BooksViewModel {
    var books: [Book] = []
    var activeLoanByBookId: [String: Loan] = [:]   // D6/§7.3: Özet ile aynı kaynak
    var searchText: String = ""
    var filterIndex: Int = 0    // 0=Hepsi 1=Rafta 2=Ödünçte
    var isLoading: Bool = true
    var errorMessage: String? = nil
    var showingAddForm: Bool = false

    let bookRepo: any BookRepository
    private let loanRepo: any LoanRepository

    init(bookRepo: any BookRepository, loanRepo: any LoanRepository) {
        self.bookRepo = bookRepo
        self.loanRepo = loanRepo
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

    // D6/§7.3: Gecikme tek kaynaktan — aktif loan'ın borrowDate'i + Ayarlar.süresi.
    // Özet ekranıyla aynı hesap; book.borrowedDate fallback kullanılmaz.
    func overdueDays(for book: Book) -> Int? {
        guard book.status == .borrowed,
              let id = book.id,
              let loan = activeLoanByBookId[id] else { return nil }
        return LendingSettings.current.overdueDays(from: loan.borrowDate)
    }

    // MARK: - Gözlem (Firestore snapshot listener canlı yayın)
    // books + loans paralel dinlenir; loans tek seferde çekilip bookId'e göre
    // map'lenir → satır başına ayrı sorgu yok.

    func observe() async {
        isLoading = true
        errorMessage = nil
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in await self?.observeBooksStream() }
            group.addTask { [weak self] in await self?.observeLoansStream() }
        }
    }

    private func observeBooksStream() async {
        for await newBooks in bookRepo.observeBooks() {
            books = newBooks
            isLoading = false
        }
    }

    private func observeLoansStream() async {
        for await allLoans in loanRepo.observeLoans() {
            activeLoanByBookId = Self.buildActiveLoanMap(allLoans)
        }
    }

    // MARK: - Pull-to-refresh
    // Tek seferlik fetch — snapshot listener cache'inden bağımsız Firestore server sorgusu.
    // Books + loans paralel; loans map'i Özet ile aynı türetimle yeniden kurulur.

    func refresh() async {
        errorMessage = nil
        do {
            async let booksTask = bookRepo.fetchAllBooks()
            async let loansTask = loanRepo.fetchAllLoans()
            let (newBooks, newLoans) = try await (booksTask, loansTask)
            books = newBooks
            activeLoanByBookId = Self.buildActiveLoanMap(newLoans)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func buildActiveLoanMap(_ all: [Loan]) -> [String: Loan] {
        var map: [String: Loan] = [:]
        for loan in all where loan.isActive { map[loan.bookId] = loan }
        return map
    }
}
