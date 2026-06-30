import SwiftUI

struct BookDetailView: View {
    @Bindable var vm: BookDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    @State private var deleteBlockedMessage: String? = nil
    @State private var showingReturnConfirm = false
    @State private var lendingVM: LendingViewModel? = nil

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    statusCard
                    infoSection
                    primaryActionButton
                    loanHistorySection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingEdit = true } label: {
                        Label("Düzenle", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        attemptDelete()
                    } label: {
                        Label("Sil", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            BookFormView(
                vm: BookFormViewModel(editingBook: vm.book, bookRepo: vm.bookRepo)
            )
        }
        .sheet(item: $lendingVM) { existingVM in
            LendingSheet(vm: existingVM) {
                Task { await vm.load() }
            }
        }
        .alert("İade Al?", isPresented: $showingReturnConfirm) {
            Button("İade Al", role: .destructive) {
                Task {
                    do {
                        try await vm.returnBook()
                        await vm.load()
                    } catch {
                        vm.actionError = error.localizedDescription
                    }
                }
            }
            Button("İptal", role: .cancel) { }
        } message: {
            Text("\"\(vm.book.title)\" iade alınacak.")
        }
        .alert("Hata", isPresented: Binding(
            get: { vm.actionError != nil },
            set: { if !$0 { vm.actionError = nil } }
        )) {
            Button("Tamam") { vm.actionError = nil }
        } message: {
            Text(vm.actionError ?? "")
        }
        .alert("Kitap silinemez", isPresented: Binding(
            get: { deleteBlockedMessage != nil },
            set: { if !$0 { deleteBlockedMessage = nil } }
        )) {
            Button("Tamam") { deleteBlockedMessage = nil }
        } message: {
            Text(deleteBlockedMessage ?? "")
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
            Text("\"\(vm.book.title)\" kalıcı olarak silinecek.")
        }
        .task { await vm.load() }
    }

    // MARK: - Silme guard (§7.4 ile aynı mantık)

    private func attemptDelete() {
        if vm.book.status == .borrowed {
            deleteBlockedMessage = "Bu kitap şu an ödünçte, önce iade alınmalı."
        } else {
            showingDeleteAlert = true
        }
    }

    // MARK: - Kapak + başlık + yazar

    private var headerSection: some View {
        VStack(spacing: 10) {
            CoverPlaceholder(title: vm.book.title, width: 104, height: 150)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
            Text(vm.book.title)
                .font(.detailHeadline)
                .foregroundStyle(Color.appLabel)
                .multilineTextAlignment(.center)
            Text(vm.book.author)
                .font(.listRowSubtitle)
                .foregroundStyle(Color.appSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }

    // MARK: - Durum kartı (§6.2)

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch vm.book.status {
            case .available:
                availableStatus
            case .borrowed:
                borrowedStatus
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12))
    }

    private var availableStatus: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.appOkText)
                .frame(width: 10, height: 10)
            Text("Rafta")
                .font(.listRowTitle)
                .foregroundStyle(Color.appLabel)
            Spacer()
            if let shelf = vm.book.shelfLocation {
                Text(shelf)
                    .font(.listRowSubtitle)
                    .foregroundStyle(Color.appSecondary)
            }
        }
    }

    private var borrowedStatus: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Avatar(name: vm.borrowerName ?? "—", size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.borrowerName ?? "Üye yükleniyor…")
                        .font(.listRowTitle)
                        .foregroundStyle(Color.appLabel)
                    if let date = vm.book.borrowedDate {
                        Text("Alındı · \(date.bookShortDate)")
                            .font(.listRowSubtitle)
                            .foregroundStyle(Color.appSecondary)
                    }
                }
                Spacer()
                StatusBadge(status: vm.badgeStatus)
            }
        }
    }

    // MARK: - Bilgiler

    private var infoSection: some View {
        VStack(spacing: 0) {
            if let isbn = vm.book.isbn {
                infoRow(label: "ISBN", value: isbn)
                Divider().padding(.leading, 90)
            }
            if let cat = vm.book.category {
                infoRow(label: "Kategori", value: cat)
                Divider().padding(.leading, 90)
            }
            if let shelf = vm.book.shelfLocation {
                infoRow(label: "Raf", value: shelf)
            }
        }
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12))
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.listRowSubtitle)
                .foregroundStyle(Color.appSecondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.bodyValue)
                .foregroundStyle(Color.appLabel)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
    }

    // MARK: - Birincil buton

    private var primaryActionButton: some View {
        PrimaryButton(
            title: vm.book.status == .available ? "Ödünç Ver" : "İade Al"
        ) {
            if vm.book.status == .available {
                lendingVM = LendingViewModel(
                    book: vm.book,
                    lendingService: vm.lendingService,
                    memberRepo: FirestoreMemberRepository(),
                    loanRepo: FirestoreLoanRepository()
                )
            } else {
                showingReturnConfirm = true
            }
        }
    }

    // MARK: - Ödünç geçmişi

    @ViewBuilder
    private var loanHistorySection: some View {
        if vm.isLoadingHistory {
            LoadingView().frame(height: 80)
        } else if !vm.loanHistory.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Ödünç Geçmişi")
                    .sectionHeaderStyle()
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    ForEach(vm.loanHistory) { loan in
                        loanHistoryRow(loan)
                        if loan.id != vm.loanHistory.last?.id {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func loanHistoryRow(_ loan: Loan) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.displayName(for: loan))
                    .font(.listRowTitle)
                    .foregroundStyle(Color.appLabel)
                Text(loan.borrowDate.bookShortDate)
                    .font(.listRowSubtitle)
                    .foregroundStyle(Color.appSecondary)
            }
            Spacer()
            if loan.isActive {
                StatusBadge(status: .borrowed)
            } else if let returnDate = loan.returnDate {
                Text(returnDate.bookShortDate)
                    .font(.listRowSubtitle)
                    .foregroundStyle(Color.appTertiary)
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
    }
}

// MARK: - Tarih yardımcısı

private extension Date {
    var bookShortDate: String {
        formatted(.dateTime.day().month(.abbreviated).year()
            .locale(Locale(identifier: "tr_TR")))
    }
}

// MARK: - Preview

#Preview("Rafta") {
    NavigationStack {
        BookDetailView(
            vm: BookDetailViewModel(
                book: MockData.books[0],
                bookRepo: MockBookRepository(),
                loanRepo: MockLoanRepository(),
                memberRepo: MockMemberRepository()
            )
        )
    }
}

#Preview("Ödünçte (gecikmeli)") {
    NavigationStack {
        BookDetailView(
            vm: BookDetailViewModel(
                book: MockData.books[1],
                bookRepo: MockBookRepository(),
                loanRepo: MockLoanRepository(),
                memberRepo: MockMemberRepository()
            )
        )
    }
}

#Preview("Karanlık") {
    NavigationStack {
        BookDetailView(
            vm: BookDetailViewModel(
                book: MockData.books[1],
                bookRepo: MockBookRepository(),
                loanRepo: MockLoanRepository(),
                memberRepo: MockMemberRepository()
            )
        )
    }
    .preferredColorScheme(.dark)
}
