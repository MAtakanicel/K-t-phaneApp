import SwiftUI

// D3: Sabit .system(size:) yok — her rol bir text style'a map'lenir.
// Punto'lar referanstır; Dynamic Type kullanıcı tercihini otomatik ölçekler.
extension Font {
    // Liste satırı başlık (16/600) → callout + semibold
    static let listRowTitle: Font = .callout.weight(.semibold)

    // Liste alt bilgi / yazar (14/400) → footnote
    static let listRowSubtitle: Font = .footnote

    // Bölüm etiketi (12.5/400, BÜYÜK HARF) → caption; .textCase(.uppercase) ile kullanılır
    static let sectionHeader: Font = .caption

    // Detay ekranı başlık (23/700) → title2 + bold
    static let detailHeadline: Font = .title2.bold()

    // Gövde / form değeri (16/400) → body
    static let bodyValue: Font = .body

    // Durum rozeti / pill (12.5–13/600) → caption + semibold
    static let badgeLabel: Font = .caption.weight(.semibold)

    // Birincil buton (17/600) → headline
    static let primaryButton: Font = .headline

    // Tab etiketi (10/500) → caption2 + medium
    static let tabLabel: Font = .caption2.weight(.medium)

    // Nav / modal başlık (17/600) → headline
    static let navTitle: Font = .headline
}

// Bölüm etiketi ViewModifier — BÜYÜK HARF + tracking + secondary renk
struct SectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.sectionHeader)
            .textCase(.uppercase)
            .kerning(0.2)
            .foregroundStyle(Color.appSecondary)
    }
}

extension View {
    func sectionHeaderStyle() -> some View {
        modifier(SectionHeaderStyle())
    }
}
