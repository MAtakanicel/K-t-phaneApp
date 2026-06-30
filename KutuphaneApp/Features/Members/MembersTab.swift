import SwiftUI

// MARK: - Üretim entry point

struct MembersTab: View {
    @State private var vm = MembersViewModel(
        memberRepo: FirestoreMemberRepository(),
        loanRepo: FirestoreLoanRepository()
    )

    var body: some View {
        MembersScreen(vm: vm)
    }
}

// MARK: - Previewlanabilir liste ekranı

struct MembersScreen: View {
    @Bindable var vm: MembersViewModel
    @State private var observationId = UUID()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                mainContent
            }
            .onAppear { observationId = UUID() }
            .navigationTitle("Üyeler")
            .searchable(text: $vm.searchText, prompt: "Üye adı veya no ara")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { vm.showingAddForm = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: Member.self) { member in
                MemberDetailView(
                    vm: MemberDetailViewModel(
                        member: member,
                        memberRepo: vm.memberRepo,
                        loanRepo: FirestoreLoanRepository(),
                        bookRepo: FirestoreBookRepository()
                    )
                )
            }
            .sheet(isPresented: $vm.showingAddForm) {
                MemberFormView(vm: MemberFormViewModel(memberRepo: vm.memberRepo))
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
        } else if vm.filteredMembers.isEmpty {
            emptyView.frame(maxHeight: .infinity)
        } else {
            memberList
        }
    }

    // MARK: - Liste

    private var memberList: some View {
        List {
            ForEach(vm.filteredMembers) { member in
                NavigationLink(value: member) {
                    MemberListRow(member: member,
                                  loanCount: vm.loanCount(for: member))
                }
                .listRowBackground(Color.appSurface)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Boş durum (D4)

    @ViewBuilder
    private var emptyView: some View {
        if vm.searchText.isEmpty {
            EmptyStateView(
                icon: "person.2",
                title: "Henüz üye yok",
                description: "İlk üyeyi eklemek için + butonuna dokun.",
                actionTitle: "Üye Ekle"
            ) { vm.showingAddForm = true }
        } else {
            EmptyStateView(
                icon: "magnifyingglass",
                title: "Sonuç bulunamadı",
                description: "Farklı bir ad veya üye no deneyin."
            )
        }
    }
}

// MARK: - Member Hashable (NavigationLink value için)

extension Member: Hashable {
    public static func == (lhs: Member, rhs: Member) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Preview

#Preview("Liste — dolu") {
    MembersScreen(vm: {
        let vm = MembersViewModel(
            memberRepo: MockMemberRepository(),
            loanRepo: MockLoanRepository()
        )
        vm.isLoading = false
        vm.loanCounts = ["member-1": 1, "member-2": 0]
        return vm
    }())
}

#Preview("Liste — boş") {
    MembersScreen(vm: {
        let vm = MembersViewModel(
            memberRepo: MockMemberRepository(members: []),
            loanRepo: MockLoanRepository()
        )
        vm.isLoading = false
        return vm
    }())
}

#Preview("Karanlık") {
    MembersScreen(vm: {
        let vm = MembersViewModel(
            memberRepo: MockMemberRepository(),
            loanRepo: MockLoanRepository()
        )
        vm.isLoading = false
        vm.loanCounts = ["member-1": 3, "member-2": 1]
        return vm
    }())
    .preferredColorScheme(.dark)
}
