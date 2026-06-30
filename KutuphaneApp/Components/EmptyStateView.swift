import SwiftUI

// §5.10 — Boş durum kartı: yuvarlak ikon kabı + başlık + açıklama + opsiyonel buton.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.appFieldBg)
                    .frame(width: 72, height: 72)
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color.appTertiary)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.appLabel)
                    .multilineTextAlignment(.center)
                Text(description)
                    .font(.listRowSubtitle)
                    .foregroundStyle(Color.appSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button {
                    action()
                } label: {
                    Text(actionTitle)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.appAccent, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ScrollView {
        EmptyStateView(
            icon: "book.closed",
            title: "Henüz kitap eklenmedi",
            description: "İlk kitabı eklemek için + butonuna dokun.",
            actionTitle: "Kitap Ekle"
        ) { }
        EmptyStateView(
            icon: "magnifyingglass",
            title: "Sonuç bulunamadı",
            description: "Farklı bir arama terimi dene."
        )
    }
    .background(Color.appBg)
}
