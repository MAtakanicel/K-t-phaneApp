import SwiftUI

struct LendingSheet: View {
    @Bindable var vm: LendingViewModel
    @Environment(\.dismiss) private var dismiss
    var onComplete: () -> Void = {}

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                Group {
                    switch vm.state {
                    case .selectingMember:
                        memberSelectionView
                    case .limitReached(let member):
                        limitReachedView(member: member)
                    case .confirming(let member):
                        confirmingView(member: member)
                    }
                }
            }
            .navigationTitle("Ödünç Ver")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
            .alert("Hata", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("Tamam") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
        .task { await vm.loadMembers() }
    }

    // MARK: - Durum (a): Üye seçimi

    private var memberSelectionView: some View {
        VStack(spacing: 0) {
            // Kitap özeti
            bookSummaryBanner

            // Arama
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.appTertiary)
                TextField("Üye adı veya numara", text: $vm.searchText)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .padding(10)
            .background(Color.appFieldBg, in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Üye listesi
            if vm.isLoadingMembers {
                Spacer()
                LoadingView()
                Spacer()
            } else if vm.filteredMembers.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "Sonuç bulunamadı",
                    description: "Farklı bir ad veya numara deneyin."
                )
                Spacer()
            } else {
                List {
                    ForEach(vm.filteredMembers) { member in
                        Button {
                            vm.selectMember(member)
                        } label: {
                            memberRow(member)
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

    private func memberRow(_ member: Member) -> some View {
        let count = vm.loanCounts[member.id ?? ""] ?? 0
        return HStack(spacing: 12) {
            Avatar(name: member.fullName, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(member.fullName)
                    .font(.listRowTitle)
                    .foregroundStyle(Color.appLabel)
                Text("No: \(member.memberNumber)")
                    .font(.listRowSubtitle)
                    .foregroundStyle(Color.appSecondary)
            }
            Spacer()
            FillIndicator(count: count)
        }
        .frame(minHeight: 56)
    }

    // MARK: - Durum (b): Limit dolu

    private func limitReachedView(member: Member) -> some View {
        VStack(spacing: 0) {
            bookSummaryBanner

            // Kırmızı uyarı bandı
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.appWarnText)
                Text("\(member.fullName) üzerinde 3 kitap var — ödünç verilemiyor.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.appWarnText)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appWarnBg, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
            .padding(.vertical, 16)

            // Özet kartı
            summaryCard(member: member, accent: false)

            Spacer()

            // Alt butonlar
            VStack(spacing: 12) {
                PrimaryButton(title: "Onayla") { }
                    .disabled(true)
                    .opacity(0.4)

                Button("‹ Başka üye seç") {
                    vm.resetToSelecting()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.appAccent)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Durum (c): Onay özeti

    private func confirmingView(member: Member) -> some View {
        VStack(spacing: 0) {
            bookSummaryBanner

            summaryCard(member: member, accent: true)

            Spacer()

            VStack(spacing: 12) {
                PrimaryButton(title: vm.isConfirming ? "Kaydediliyor…" : "Onayla") {
                    Task {
                        do {
                            try await vm.confirm()
                            dismiss()
                            onComplete()
                        } catch {
                            vm.errorMessage = error.localizedDescription
                        }
                    }
                }
                .disabled(vm.isConfirming)

                Button("‹ Başka üye seç") {
                    vm.resetToSelecting()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.appAccent)
                .disabled(vm.isConfirming)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Ortak alt görünümler

    private var bookSummaryBanner: some View {
        HStack(spacing: 12) {
            BookCover.compact(title: vm.book.title, coverURL: vm.book.coverImageURL)
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.book.title)
                    .font(.listRowTitle)
                    .foregroundStyle(Color.appLabel)
                    .lineLimit(1)
                Text(vm.book.author)
                    .font(.listRowSubtitle)
                    .foregroundStyle(Color.appSecondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appSurface)
    }

    private func summaryCard(member: Member, accent: Bool) -> some View {
        VStack(spacing: 0) {
            summaryRow(label: "Kitap",
                       value: vm.book.title,
                       icon: "book.closed")
            Divider().padding(.leading, 52)
            summaryRow(label: "Üye",
                       value: "\(member.fullName) (No: \(member.memberNumber))",
                       icon: "person")
            Divider().padding(.leading, 52)
            summaryRow(label: "İade Tarihi",
                       value: vm.dueDate.lendingShortDate,
                       icon: "calendar")
        }
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func summaryRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 28)
                .foregroundStyle(Color.appSecondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.appTertiary)
                Text(value)
                    .font(.listRowTitle)
                    .foregroundStyle(Color.appLabel)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
    }
}

// MARK: - Tarih yardımcısı

private extension Date {
    var lendingShortDate: String {
        formatted(.dateTime.day().month(.abbreviated).year()
            .locale(Locale(identifier: "tr_TR")))
    }
}

// MARK: - Preview

#Preview("Üye seçimi") {
    LendingSheet(
        vm: LendingViewModel(
            book: MockData.books[0],
            lendingService: MockLendingService(),
            memberRepo: MockMemberRepository(),
            loanRepo: MockLoanRepository()
        )
    )
}

#Preview("Limit dolu") {
    let vm = LendingViewModel(
        book: MockData.books[0],
        lendingService: MockLendingService(),
        memberRepo: MockMemberRepository(),
        loanRepo: MockLoanRepository()
    )
    vm.members = MockData.members
    vm.loanCounts = [MockData.members[0].id ?? "": 3]
    vm.state = .limitReached(member: MockData.members[0])
    return LendingSheet(vm: vm)
}

#Preview("Onay özeti") {
    let vm = LendingViewModel(
        book: MockData.books[0],
        lendingService: MockLendingService(),
        memberRepo: MockMemberRepository(),
        loanRepo: MockLoanRepository()
    )
    vm.state = .confirming(member: MockData.members[1])
    return LendingSheet(vm: vm)
}

#Preview("Karanlık") {
    LendingSheet(
        vm: LendingViewModel(
            book: MockData.books[0],
            lendingService: MockLendingService(),
            memberRepo: MockMemberRepository(),
            loanRepo: MockLoanRepository()
        )
    )
    .preferredColorScheme(.dark)
}
