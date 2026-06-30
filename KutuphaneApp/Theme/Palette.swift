// Tema token'larının ham UIColor değerleri.
// #if canImport(UIKit) → iOS build'de derlenir; macOS SourceKit analizi sessiz geçer.
#if canImport(UIKit)
import UIKit

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: alpha)
    }
}

// Adaptive UIColor token'ları — Color+Theme.swift tarafından SwiftUI Color'a çevrilir
extension UIColor {
    static let appBg = UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "141312") : UIColor(hex: "ECEAE4")
    }
    static let appSurface = UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "211F1C") : UIColor(hex: "FFFFFF")
    }
    static let appLabel = UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "F5F3EE") : UIColor(hex: "1A1A18")
    }
    // D2: secondary koyulaştırıldı — light #6E6C66 (orijinal #86847E), dark 0.72 (orijinal 0.60)
    static let appSecondary = UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "F5F3EE", alpha: 0.72) : UIColor(hex: "6E6C66")
    }
    static let appTertiary = UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "F5F3EE", alpha: 0.32) : UIColor(hex: "B6B4AD")
    }
    static let appSeparator = UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "FFFFFF", alpha: 0.10) : UIColor(hex: "1A1A18", alpha: 0.08)
    }
    static let appAccent = UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "34C77F") : UIColor(hex: "1FA066")
    }
    static let appFieldBg = UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "FFFFFF", alpha: 0.10) : UIColor(hex: "E2E0D8")
    }
    static let appSegSelected = UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "3A3833") : UIColor(hex: "FFFFFF")
    }
    static let appOkText = UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "34C77F") : UIColor(hex: "1F9D5F")
    }
    static let appOkBg = UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "34C77F", alpha: 0.18) : UIColor(hex: "1F9D5F", alpha: 0.13)
    }
    static let appNeutText = UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "F5F3EE", alpha: 0.60) : UIColor(hex: "86847E")
    }
    static let appNeutBg = UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "FFFFFF", alpha: 0.12) : UIColor(hex: "78766E", alpha: 0.14)
    }
    static let appWarnText = UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "FF6B5E") : UIColor(hex: "D6453B")
    }
    static let appWarnBg = UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "FF6B5E", alpha: 0.20) : UIColor(hex: "D6453B", alpha: 0.12)
    }
    static let appTabBg = UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "141312", alpha: 0.92) : UIColor(hex: "ECEAE4", alpha: 0.90)
    }
    static let appTabInactive = UIColor { _ in UIColor(hex: "A4A29A") }
    static let appSheetBg = UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "211F1C") : UIColor(hex: "ECEAE4")
    }
    static let appSheetCard = UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "2B2926") : UIColor(hex: "FFFFFF")
    }
    static let appDisabledBg  = UIColor { _ in UIColor(hex: "78766E", alpha: 0.16) }
    static let appDisabledText = UIColor { _ in UIColor(hex: "1A1A18", alpha: 0.32) }
}
#endif
