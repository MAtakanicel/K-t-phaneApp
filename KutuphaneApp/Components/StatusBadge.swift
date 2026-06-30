import SwiftUI

// §5.1 — Kitap durum rozeti (pill). Renkler D2 semantiğine uygun.
// Yeşil = rafta/müsait, gri = ödünçte (nötr), kırmızı = SADECE gecikme/limit engeli.
enum BookBadgeStatus {
    case available                  // Rafta
    case borrowed                   // Ödünçte
    case overdue(days: Int)         // "N gün gecikti" — detay ekranları
    case overdueShort               // "Gecikti" — liste satırı (gün sayısı yok)
}

struct StatusBadge: View {
    let status: BookBadgeStatus

    private var label: String {
        switch status {
        case .available:          return "Rafta"
        case .borrowed:           return "Ödünçte"
        case .overdue(let days):  return "\(days) gün gecikti"
        case .overdueShort:       return "Gecikti"
        }
    }

    private var textColor: Color {
        switch status {
        case .available:                  return .appOkText
        case .borrowed:                   return .appNeutText
        case .overdue, .overdueShort:     return .appWarnText
        }
    }

    private var bgColor: Color {
        switch status {
        case .available:                  return .appOkBg
        case .borrowed:                   return .appNeutBg
        case .overdue, .overdueShort:     return .appWarnBg
        }
    }

    var body: some View {
        Text(label)
            .font(.badgeLabel)
            .foregroundStyle(textColor)
            .padding(.vertical, 3)
            .padding(.horizontal, 9)
            .background(bgColor, in: RoundedRectangle(cornerRadius: 7))
    }
}

// Book.status + opsiyonel gecikme günü → StatusBadge dönüştürücü.
// `compactOverdue=true` → liste satırı: "Gecikti" (gün sayısız).
// Detay ekranları false bırakır → "N gün gecikti".
extension StatusBadge {
    init(bookStatus: BookStatus,
         overdueDays: Int? = nil,
         compactOverdue: Bool = false) {
        switch bookStatus {
        case .available:
            status = .available
        case .borrowed:
            if let days = overdueDays, days > 0 {
                status = compactOverdue ? .overdueShort : .overdue(days: days)
            } else {
                status = .borrowed
            }
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        StatusBadge(status: .available)
        StatusBadge(status: .borrowed)
        StatusBadge(status: .overdue(days: 5))
    }
    .padding()
    .background(Color.appBg)
}
