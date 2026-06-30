import SwiftUI

// MARK: - Üretim entry point (Firestore repo)

struct BooksTab: View {
    @State private var vm = BooksViewModel(bookRepo: FirestoreBookRepository())

    var body: some View {
        BooksScreen(vm: vm)
    }
}

// MARK: - Previewlanabilir liste ekranı

struct BooksScreen: View {
    @Bindable var vm: BooksViewModel
    @State private var observationId = UUID()
    @State private var showingScanner = false
    @State private var path = NavigationPath()
    @State private var scanError: String? = nil

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.appBg.ignoresSafeArea()
                mainContent
            }
            .onAppear { observationId = UUID() }
            .navigationTitle("Kitaplar")
            .searchable(text: $vm.searchText, prompt: "Kitap veya yazar ara")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        print("[BooksScreen] barcode toolbar tapped → showingScanner=true")
                        showingScanner = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                    }
                    Button { vm.showingAddForm = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: Book.self) { book in
                BookDetailView(
                    vm: BookDetailViewModel(
                        book: book,
                        bookRepo: vm.bookRepo,
                        loanRepo: FirestoreLoanRepository(),
                        memberRepo: FirestoreMemberRepository()
                    )
                )
            }
            .sheet(isPresented: $vm.showingAddForm) {
                BookFormView(vm: BookFormViewModel(bookRepo: vm.bookRepo))
            }
            .fullScreenCover(isPresented: $showingScanner) {
                ScannerView(mode: .isbn) { code in
                    print("[BooksScreen] scanner returned ISBN=\(code)")
                    Task { await lookupBook(isbn: code) }
                }
            }
            .alert("Kitap bulunamadı", isPresented: Binding(
                get: { scanError != nil },
                set: { if !$0 { scanError = nil } }
            )) {
                Button("Tamam") { scanError = nil }
            } message: {
                Text(scanError ?? "")
            }
        }
        .tint(Color.appAccent)
        .task(id: observationId) { await vm.observe() }
    }

    private func lookupBook(isbn: String) async {
        do {
            if let book = try await vm.bookRepo.findByISBN(isbn) {
                print("[BooksScreen] book found → pushing detail")
                path.append(book)
            } else {
                print("[BooksScreen] no book for ISBN=\(isbn)")
                scanError = "Bu ISBN ile kayıtlı kitap yok: \(isbn)"
            }
        } catch {
            print("[BooksScreen] findByISBN error: \(error)")
            scanError = error.localizedDescription
        }
    }

    // MARK: - State routing (D4)

    @ViewBuilder
    private var mainContent: some View {
        if vm.isLoading {
            LoadingView()
        } else if let msg = vm.errorMessage {
            ErrorView(message: msg) { Task { await vm.observe() } }
        } else {
            booksContent
        }
    }

    // MARK: - Liste + segmented filtre

    private var booksContent: some View {
        VStack(spacing: 0) {
            AppSegmentedControl(
                options: ["Hepsi", "Rafta", "Ödünçte"],
                selection: $vm.filterIndex
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.appBg)

            if vm.filteredBooks.isEmpty {
                emptyView
                    .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(vm.filteredBooks) { book in
                        NavigationLink(value: book) {
                            BookListRow(book: book,
                                        overdueDays: vm.overdueDays(for: book))
                        }
                        .listRowBackground(Color.appSurface)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    // MARK: - Boş durum (D4)

    @ViewBuilder
    private var emptyView: some View {
        if vm.searchText.isEmpty && vm.filterIndex == 0 {
            EmptyStateView(
                icon: "book.closed",
                title: "Henüz kitap eklenmedi",
                description: "Kütüphanenize ilk kitabı ekleyin.",
                actionTitle: "Kitap Ekle"
            ) { vm.showingAddForm = true }
        } else {
            EmptyStateView(
                icon: "magnifyingglass",
                title: "Sonuç bulunamadı",
                description: "Farklı bir arama veya filtre deneyin."
            )
        }
    }
}

// MARK: - Preview

#Preview("Liste — dolu") {
    BooksScreen(vm: {
        let vm = BooksViewModel(bookRepo: MockBookRepository())
        vm.isLoading = false
        return vm
    }())
}

#Preview("Liste — boş") {
    BooksScreen(vm: {
        let vm = BooksViewModel(bookRepo: MockBookRepository(books: []))
        vm.isLoading = false
        return vm
    }())
}

#Preview("Yükleniyor") {
    BooksScreen(vm: BooksViewModel(bookRepo: MockBookRepository()))
}

#Preview("Karanlık") {
    BooksScreen(vm: {
        let vm = BooksViewModel(bookRepo: MockBookRepository())
        vm.isLoading = false
        return vm
    }())
    .preferredColorScheme(.dark)
}
