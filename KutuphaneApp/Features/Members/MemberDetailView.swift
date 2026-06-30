import SwiftUI

struct MemberDetailView: View {
    @Bindable var vm: MemberDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var deleteAlertMessage: String? = nil
    @State private var showingDeleteConfirm = false
    @State private var returningBookId: String? = nil

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    activeBooksSection
                    contactSection
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
                    Button(role: .destructive) { attemptDelete() } label: {
                        Label("Sil", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            MemberFormView(
                vm: MemberFormViewModel(editingMember: vm.member,
                                        memberRepo: vm.memberRepo)
            )
        }
        // §7.4: Engelleyici alert — üzerinde kitap varsa
        .alert("Üye silinemez", isPresented: Binding(
            get: { deleteAlertMessage != nil },
            set: { if !$0 { deleteAlertMessage = nil } }
        )) {
            Button("Tamam") { deleteAlertMessage = nil }
        } message: {
            Text(deleteAlertMessage ?? "")
        }
        // Normal silme onayı
        .alert("Üyeyi sil?", isPresented: $showingDeleteConfirm) {
            Button("Sil", role: .destructive) {
                Task {
                    try? await vm.delete()
                    dismiss()
                }
            }
            Button("İptal", role: .cancel) { }
        } message: {
            Text("\"\(vm.member.fullName)\" kalıcı olarak silinecek.")
        }
        // İade onayı
        .alert("İade Al?", isPresented: Binding(
            get: { returningBookId != nil },
            set: { if !$0 { returningBookId = nil } }
        )) {
            Button("İade Al", role: .destructive) {
                guard let bookId = returningBookId else { return }
                returningBookId = nil
                Task {
                    do {
                        try await vm.returnBook(bookId: bookId)
                    } catch {
                        vm.returnError = error.localizedDescription
                    }
                }
            }
            Button("İptal", role: .cancel) { returningBookId = nil }
        } message: {
            Text("Kitap iade alınacak.")
        }
        .alert("Hata", isPresented: Binding(
            get: { vm.returnError != nil },
            set: { if !$0 { vm.returnError = nil } }
        )) {
            Button("Tamam") { vm.returnError = nil }
        } message: {
            Text(vm.returnError ?? "")
        }
        .task { await vm.load() }
    }

    // MARK: - Silme denemesi (§7.4)

    private func attemptDelete() {
        if vm.canDelete {
            showingDeleteConfirm = true
        } else {
            deleteAlertMessage =
                "\(vm.member.fullName) üzerinde \(vm.loanCount) kitap var. Önce iade alınmalı."
        }
    }

    // MARK: - Avatar + ad + no + doluluk

    private var headerSection: some View {
        VStack(spacing: 10) {
            Avatar(name: vm.member.fullName, size: 76)
            Text(vm.member.fullName)
                .font(.detailHeadline)
                .foregroundStyle(Color.appLabel)
                .multilineTextAlignment(.center)
            Text("No: \(vm.member.memberNumber)")
                .font(.listRowSubtitle)
                .foregroundStyle(Color.appSecondary)
            FillIndicator(count: vm.loanCount)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }

    // MARK: - Üzerindeki kitaplar (§6.5)

    @ViewBuilder
    private var activeBooksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Üzerindeki Kitaplar")
                .sectionHeaderStyle()
                .padding(.horizontal, 4)

            if vm.isLoading {
                LoadingView().frame(height: 80)
            } else if vm.activeItems.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "Üzerinde kitap yok",
                    description: "Bu üyenin şu an aktif ödüncü bulunmuyor."
                )
                .frame(maxWidth: .infinity)
                .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 0) {
                    ForEach(vm.activeItems) { item in
                        activeBookRow(item)
                        if item.id != vm.activeItems.last?.id {
                            Divider().padding(.leading, 70)
                        }
                    }
                }
                .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func activeBookRow(_ item: LoanWithBook) -> some View {
        let overdue = vm.overdueDays(for: item.loan)
        let dateColor: Color = overdue != nil ? .appWarnText : .appSecondary

        return HStack(spacing: 12) {
            CoverPlaceholder.compact(title: item.book.title)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.book.title)
                    .font(.listRowTitle)
                    .foregroundStyle(Color.appLabel)
                    .lineLimit(1)
                if let borrowDate = item.loan.borrowDate as Date? {
                    Text("Alındı · \(borrowDate.bookShortDate)")
                        .font(.listRowSubtitle)
                        .foregroundStyle(dateColor)
                }
                if let days = overdue {
                    Text("\(days) gün gecikti")
                        .font(.badgeLabel)
                        .foregroundStyle(Color.appWarnText)
                }
            }

            Spacer()

            Button {
                returningBookId = item.book.id
            } label: {
                Text("İade Al")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.appFieldBg, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 64)
    }

    // MARK: - İletişim

    @ViewBuilder
    private var contactSection: some View {
        let hasContact = vm.member.email != nil ||
                         vm.member.phone != nil ||
                         vm.member.department != nil
        if hasContact {
            VStack(spacing: 0) {
                if let email = vm.member.email {
                    contactRow(label: "E-posta", value: email)
                    Divider().padding(.leading, 90)
                }
                if let phone = vm.member.phone {
                    contactRow(label: "Telefon", value: phone)
                    Divider().padding(.leading, 90)
                }
                if let dept = vm.member.department {
                    contactRow(label: "Bölüm", value: dept)
                }
            }
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func contactRow(label: String, value: String) -> some View {
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
}

// MARK: - Tarih yardımcısı (Book ile aynı; lokal extension)

private extension Date {
    var bookShortDate: String {
        formatted(.dateTime.day().month(.abbreviated).year()
            .locale(Locale(identifier: "tr_TR")))
    }
}

// MARK: - Preview

#Preview("Aktif kitaplı üye") {
    let mockLoan = MockLoanRepository()
    let mockBook = MockBookRepository()
    let mockMember = MockMemberRepository()
    NavigationStack {
        MemberDetailView(
            vm: MemberDetailViewModel(
                member: MockData.members[0],
                memberRepo: mockMember,
                loanRepo: mockLoan,
                bookRepo: mockBook
            )
        )
    }
}

#Preview("Kitapsız üye") {
    NavigationStack {
        MemberDetailView(
            vm: MemberDetailViewModel(
                member: MockData.members[1],
                memberRepo: MockMemberRepository(),
                loanRepo: MockLoanRepository(),
                bookRepo: MockBookRepository()
            )
        )
    }
}

#Preview("Karanlık") {
    NavigationStack {
        MemberDetailView(
            vm: MemberDetailViewModel(
                member: MockData.members[0],
                memberRepo: MockMemberRepository(),
                loanRepo: MockLoanRepository(),
                bookRepo: MockBookRepository()
            )
        )
    }
    .preferredColorScheme(.dark)
}
