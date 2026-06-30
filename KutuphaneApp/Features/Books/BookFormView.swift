import SwiftUI

struct BookFormView: View {
    @Bindable var vm: BookFormViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingScanner = false

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
                }
            }
        }
        .presentationDragIndicator(.visible)
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
