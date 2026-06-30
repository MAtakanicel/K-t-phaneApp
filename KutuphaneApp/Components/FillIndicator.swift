import SwiftUI

// §5.2 — Üye doluluk göstergesi (x/limit). Limit doluyken kırmızı.
// Limit varsayılanı Ayarlar'daki anlık değerden gelir (D6).
struct FillIndicator: View {
    let count: Int
    var limit: Int = LendingSettings.current.loanLimit

    private var isFull: Bool { count >= limit }

    var body: some View {
        Text("\(count)/\(limit)")
            .font(.badgeLabel)
            .foregroundStyle(isFull ? Color.appWarnText : Color.appSecondary)
            .padding(.vertical, 3)
            .padding(.horizontal, 9)
            .background(
                isFull ? Color.appWarnBg : Color.appFieldBg,
                in: RoundedRectangle(cornerRadius: 7)
            )
    }
}

#Preview {
    HStack(spacing: 8) {
        FillIndicator(count: 0)
        FillIndicator(count: 1)
        FillIndicator(count: 2)
        FillIndicator(count: 3)
    }
    .padding()
    .background(Color.appBg)
}
