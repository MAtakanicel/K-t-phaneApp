import SwiftUI

struct BookFormView: View {
    @Bindable var vm: BookFormViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingScanner = false
    @FocusState private var isISBNFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                Form {
                    // MARK: Temel bilgiler
                    Section {
                        FormTextField(label: "Başlık", text: $vm.title,
                                      placeholder: "Kitap adı")
                        FormTextField(label: "Yazar", text: $vm.author,
                                      placeholder: "Yazar adı")
                    }

                    // MARK: ISBN + Barkod
                    Section {
                        FormTextField(
                            label: "ISBN",
                            text: $vm.isbn,
                            placeholder: "ISBN numarası",
                            trailingIcon: "barcode.viewfinder"
                        ) {
                            showingScanner = true
                        }
                        .focused($isISBNFocused)
                        .keyboardType(.numbersAndPunctuation)
                        .submitLabel(.done)
                        .onSubmit { triggerLookupIfValid() }
                        lookupHintRow
                        FormTextField(label: "Kategori", text: $vm.category,
                                      placeholder: "Roman, Bilim Kurgu…")
                        FormTextField(label: "Raf", text: $vm.shelfLocation,
                                      placeholder: "A-01")
                    }

                    // MARK: Sil (yalnız düzenleme modunda)
                    if vm.isEditing {
                        Section {
                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                Text("Kitabı Sil")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .onChange(of: isISBNFocused) { _, focused in
                if !focused { triggerLookupIfValid() }
            }
            .navigationTitle(vm.isEditing ? "Kitabı Düzenle" : "Kitap Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kaydet") {
                        Task {
                            do {
                                try await vm.save()
                                dismiss()
                            } catch {
                                vm.errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!vm.canSave || vm.isSaving)
                }
            }
            .alert("Kitabı sil?", isPresented: $showingDeleteAlert) {
                Button("Sil", role: .destructive) {
                    Task {
                        try? await vm.delete()
                        dismiss()
                    }
                }
                Button("İptal", role: .cancel) { }
            } message: {
                Text("Bu işlem geri alınamaz.")
            }
            .alert("Hata", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("Tamam") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .fullScreenCover(isPresented: $showingScanner) {
                ScannerView(mode: .isbn) { code in
                    vm.isbn = code
                    vm.lookupISBN()
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    // Geçerli ISBN uzunluğu: 13 hane (EAN-13) veya 10 hane (ISBN-10; X bitebilir).
    private func triggerLookupIfValid() {
        let digits = vm.isbn.filter { $0.isNumber || $0 == "X" || $0 == "x" }
        guard digits.count == 10 || digits.count == 13 else { return }
        vm.lookupISBN()
    }

    // §5.4 — "✓ Google Books'tan dolduruldu" ipucu satırı + D4 düşüşleri
    @ViewBuilder
    private var lookupHintRow: some View {
        if vm.isLookingUp {
            HStack(spacing: 8) {
                ProgressView().controlSize(.small).tint(Color.appAccent)
                Text("Google Books'tan aranıyor…")
                    .font(.caption)
                    .foregroundStyle(Color.appSecondary)
                Spacer()
            }
        } else if let hint = vm.lookupHint {
            HStack(spacing: 8) {
                Image(systemName: hint == .filled ? "checkmark.circle.fill"
                                                  : "exclamationmark.circle")
                    .foregroundStyle(hint == .filled ? Color.appOkText : Color.appSecondary)
                Text(hint.message)
                    .font(.caption)
                    .foregroundStyle(hint == .filled ? Color.appOkText : Color.appSecondary)
                Spacer()
            }
        } else {
            EmptyView()
        }
    }
}

private extension BookFormViewModel.LookupHint {
    var message: String {
        switch self {
        case .filled:       return "Google Books'tan dolduruldu"
        case .notFound:     return "Sonuç bulunamadı, elle girebilirsin."
        case .networkError: return "Şu an kitap bilgisi alınamıyor, elle girebilirsiniz."
        }
    }
}

// MARK: - Preview

#Preview("Yeni kitap") {
    BookFormView(vm: BookFormViewModel(bookRepo: MockBookRepository()))
}

#Preview("Düzenle") {
    BookFormView(
        vm: BookFormViewModel(editingBook: MockData.books[0],
                              bookRepo: MockBookRepository())
    )
}

#Preview("Karanlık") {
    BookFormView(vm: BookFormViewModel(bookRepo: MockBookRepository()))
        .preferredColorScheme(.dark)
}
