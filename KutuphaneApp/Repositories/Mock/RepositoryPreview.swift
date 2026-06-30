import SwiftUI

// Mock repo'larla kitap+üye listesi — Faz 1 kabul kriteri preview'u
struct RepositoryPreviewView: View {
    @State private var books: [Book] = []
    @State private var members: [Member] = []

    private let bookRepo: any BookRepository = MockBookRepository()
    private let memberRepo: any MemberRepository = MockMemberRepository()
    private let loanRepo: any LoanRepository = MockLoanRepository()

    var body: some View {
        NavigationStack {
            List {
                Section("Kitaplar (\(books.count))") {
                    ForEach(books) { book in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(book.title)
                                .font(.listRowTitle)
                                .foregroundStyle(Color.appLabel)
                            Text(book.author)
                                .font(.listRowSubtitle)
                                .foregroundStyle(Color.appSecondary)
                            Text(book.status == .available ? "Rafta" : "Ödünçte")
                                .font(.badgeLabel)
                                .foregroundStyle(book.status == .available ? Color.appOkText : Color.appNeutText)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section("Üyeler (\(members.count))") {
                    ForEach(members) { member in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.fullName)
                                .font(.listRowTitle)
                                .foregroundStyle(Color.appLabel)
                            Text("No: \(member.memberNumber)")
                                .font(.listRowSubtitle)
                                .foregroundStyle(Color.appSecondary)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section("Loan.isActive / isOverdue kontrolü") {
                    ForEach(MockData.loans) { loan in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loan.bookTitleSnapshot ?? loan.bookId)
                                .font(.listRowTitle)
                                .foregroundStyle(Color.appLabel)
                            Text(loan.isActive ? "Aktif" : "İade edildi")
                                .font(.listRowSubtitle)
                                .foregroundStyle(Color.appSecondary)
                            if loan.isOverdue {
                                Text("GECİKMİŞ")
                                    .font(.badgeLabel)
                                    .foregroundStyle(Color.appWarnText)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Faz 1 Preview")
        }
        .task {
            for await newBooks in bookRepo.observeBooks() {
                books = newBooks
                break  // Mock tek seferlik yayın; canlı dinleyici Faz 3'te
            }
            for await newMembers in memberRepo.observeMembers() {
                members = newMembers
                break
            }
        }
    }
}

#Preview("Light") { RepositoryPreviewView() }
#Preview("Dark")  { RepositoryPreviewView().preferredColorScheme(.dark) }
