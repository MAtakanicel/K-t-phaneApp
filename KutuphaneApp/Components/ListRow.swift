import SwiftUI

// §5.3 — Genel amaçlı liste satırı.
// leading: kapak/avatar, trailing: rozet. Opsiyonel detay satırı ödünçteki üye bilgisi için.
struct ListRow<Leading: View, Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    var detail: String? = nil          // Ödünçteki kitapta "👤 Ad S." satırı
    var detailColor: Color = Color.appSecondary
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 12) {
            leading()

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.listRowTitle)
                    .foregroundStyle(Color.appLabel)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.listRowSubtitle)
                        .foregroundStyle(Color.appSecondary)
                        .lineLimit(1)
                }
                if let detail {
                    Label(detail, systemImage: "person")
                        .font(.caption)
                        .foregroundStyle(detailColor)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            trailing()
        }
        .padding(.vertical, 10)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
        // §5.3: ayraç leading/avatar + spacing sonrası başlasın
        .alignmentGuide(.listRowSeparatorLeading) { d in d[.leading] + 52 }
    }
}

// MARK: - Kitap satırı kolaylığı

struct BookListRow: View {
    let book: Book
    var overdueDays: Int? = nil

    var body: some View {
        ListRow(
            title: book.title,
            subtitle: book.author,
            leading: { BookCover.compact(title: book.title, coverURL: book.coverImageURL) },
            trailing: {
                StatusBadge(bookStatus: book.status,
                            overdueDays: overdueDays,
                            compactOverdue: true)
            }
        )
    }
}

// MARK: - Üye satırı kolaylığı

struct MemberListRow: View {
    let member: Member
    var loanCount: Int = 0

    var body: some View {
        ListRow(
            title: member.fullName,
            subtitle: "No: \(member.memberNumber)",
            leading: { Avatar(name: member.fullName) },
            trailing: { FillIndicator(count: loanCount) }
        )
    }
}

// MARK: - Preview

#Preview {
    let book1 = MockData.books[0]
    let book2 = MockData.books[1]
    let member = MockData.members[0]

    List {
        Section("Kitaplar") {
            BookListRow(book: book1)
            BookListRow(book: book2, overdueDays: 3)
        }
        Section("Üyeler") {
            MemberListRow(member: member, loanCount: 1)
            MemberListRow(member: MockData.members[1], loanCount: 3)
        }
    }
    .scrollContentBackground(.hidden)
    .background(Color.appBg)
}
