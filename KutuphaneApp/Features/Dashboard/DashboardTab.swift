import SwiftUI

// MARK: - Üretim entry point

struct DashboardTab: View {
    @State private var vm = DashboardViewModel(
        bookRepo: FirestoreBookRepository(),
        memberRepo: FirestoreMemberRepository(),
        loanRepo: FirestoreLoanRepository()
    )

    var body: some View {
        DashboardScreen(vm: vm)
    }
}

// MARK: - Previewlanabilir ekran

struct DashboardScreen: View {
    @Bindable var vm: DashboardViewModel
    @State private var observationId = UUID()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                mainContent
            }
            .onAppear {
                observationId = UUID()
                // Ayarlar değişirse sayaçlar/gecikmiş liste hemen tazelensin (D6).
                vm.recompute()
            }
            .navigationTitle("Özet")
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
        }
        .tint(Color.appAccent)
        .task(id: observationId) { await vm.observe() }
    }

    // MARK: - State routing (D4)

    @ViewBuilder
    private var mainContent: some View {
        if vm.isLoading {
            LoadingView()
        } else if let msg = vm.errorMessage {
            ErrorView(message: msg) { Task { await vm.observe() } }
        } else {
            content
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 24) {
                statsGrid
                overdueSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .refreshable { await vm.refresh() }
    }

    // MARK: - 2×2 istatistik kartları (§6.7)

    private var statsGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12),
                       GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            StatCard(title: "Toplam Kitap",
                     value: "\(vm.totalBooks)",
                     valueColor: .appLabel)
            StatCard(title: "Rafta",
                     value: "\(vm.availableCount)",
                     valueColor: .appOkText)
            StatCard(title: "Ödünçte",
                     value: "\(vm.borrowedCount)",
                     valueColor: .appLabel)
            StatCard(title: "Gecikmiş",
                     value: "\(vm.overdueCount)",
                     valueColor: vm.overdueCount > 0 ? .appWarnText : .appLabel)
        }
    }

    // MARK: - Gecikmiş kitaplar (§6.7)

    @ViewBuilder
    private var overdueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gecikmiş Kitaplar")
                .sectionHeaderStyle()
                .padding(.horizontal, 4)

            if vm.overdueItems.isEmpty {
                overdueEmptyCard
            } else {
                VStack(spacing: 0) {
                    ForEach(vm.overdueItems) { item in
                        NavigationLink(value: item.book) {
                            overdueRow(item)
                        }
                        .buttonStyle(.plain)
                        if item.id != vm.overdueItems.last?.id {
                            Divider().padding(.leading, 62)
                        }
                    }
                }
                .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var overdueEmptyCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.appOkText)
            Text("Gecikmiş kitap yok")
                .font(.listRowTitle)
                .foregroundStyle(Color.appOkText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.appOkBg, in: RoundedRectangle(cornerRadius: 12))
    }

    private func overdueRow(_ item: OverdueItem) -> some View {
        HStack(spacing: 12) {
            BookCover.compact(title: item.book.title, coverURL: item.book.coverImageURL)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.book.title)
                    .font(.listRowTitle)
                    .foregroundStyle(Color.appLabel)
                    .lineLimit(1)
                Text(item.memberName)
                    .font(.listRowSubtitle)
                    .foregroundStyle(Color.appSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text("\(item.overdueDays) gün")
                .font(.badgeLabel)
                .foregroundStyle(Color.appWarnText)
                .padding(.vertical, 3)
                .padding(.horizontal, 9)
                .background(Color.appWarnBg, in: RoundedRectangle(cornerRadius: 7))
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTertiary)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 64)
        .contentShape(Rectangle())
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let title: String
    let value: String
    let valueColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.listRowSubtitle)
                .foregroundStyle(Color.appSecondary)
            Text(value)
                .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Preview

#Preview("Dolu — gecikmeli") {
    DashboardScreen(vm: {
        let vm = DashboardViewModel(
            bookRepo: MockBookRepository(),
            memberRepo: MockMemberRepository(),
            loanRepo: MockLoanRepository()
        )
        vm.books = MockData.books
        vm.members = MockData.members
        vm.loans = MockData.loans
        vm.recompute()
        vm.isLoading = false
        return vm
    }())
}

#Preview("Gecikme yok") {
    DashboardScreen(vm: {
        let vm = DashboardViewModel(
            bookRepo: MockBookRepository(),
            memberRepo: MockMemberRepository(),
            loanRepo: MockLoanRepository(loans: [])
        )
        vm.books = MockData.books
        vm.members = MockData.members
        vm.loans = []
        vm.recompute()
        vm.isLoading = false
        return vm
    }())
}

#Preview("Yükleniyor") {
    DashboardScreen(vm: DashboardViewModel(
        bookRepo: MockBookRepository(),
        memberRepo: MockMemberRepository(),
        loanRepo: MockLoanRepository()
    ))
}

#Preview("Karanlık") {
    DashboardScreen(vm: {
        let vm = DashboardViewModel(
            bookRepo: MockBookRepository(),
            memberRepo: MockMemberRepository(),
            loanRepo: MockLoanRepository()
        )
        vm.books = MockData.books
        vm.members = MockData.members
        vm.loans = MockData.loans
        vm.recompute()
        vm.isLoading = false
        return vm
    }())
    .preferredColorScheme(.dark)
}
