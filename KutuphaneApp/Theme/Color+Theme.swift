import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// Adaptive SwiftUI Color token'ları.
// Tüm uygulama bu extension üzerinden renklere erişir; sabit değer gömülmez (D2).
extension Color {
#if canImport(UIKit)
    static let appBg           = Color(uiColor: .appBg)
    static let appSurface      = Color(uiColor: .appSurface)
    static let appLabel        = Color(uiColor: .appLabel)
    static let appSecondary    = Color(uiColor: .appSecondary)   // D2 düzeltmesi
    static let appTertiary     = Color(uiColor: .appTertiary)
    static let appSeparator    = Color(uiColor: .appSeparator)
    static let appAccent       = Color(uiColor: .appAccent)
    static let appFieldBg      = Color(uiColor: .appFieldBg)
    static let appSegSelected  = Color(uiColor: .appSegSelected)
    static let appOkText       = Color(uiColor: .appOkText)
    static let appOkBg         = Color(uiColor: .appOkBg)
    static let appNeutText     = Color(uiColor: .appNeutText)
    static let appNeutBg       = Color(uiColor: .appNeutBg)
    static let appWarnText     = Color(uiColor: .appWarnText)
    static let appWarnBg       = Color(uiColor: .appWarnBg)
    static let appTabBg        = Color(uiColor: .appTabBg)
    static let appTabInactive  = Color(uiColor: .appTabInactive)
    static let appSheetBg      = Color(uiColor: .appSheetBg)
    static let appSheetCard    = Color(uiColor: .appSheetCard)
    static let appDisabledBg   = Color(uiColor: .appDisabledBg)
    static let appDisabledText = Color(uiColor: .appDisabledText)
#else
    // Non-UIKit ortamı için light-mode sabit değerler (iOS build'de kullanılmaz)
    static let appBg           = Color(.sRGB, red: 0.925, green: 0.918, blue: 0.894)
    static let appSurface      = Color(.sRGB, red: 1.0,   green: 1.0,   blue: 1.0)
    static let appLabel        = Color(.sRGB, red: 0.102, green: 0.102, blue: 0.094)
    static let appSecondary    = Color(.sRGB, red: 0.431, green: 0.424, blue: 0.400)
    static let appTertiary     = Color(.sRGB, red: 0.714, green: 0.706, blue: 0.678)
    static let appSeparator    = Color(.sRGB, red: 0.102, green: 0.102, blue: 0.094, opacity: 0.08)
    static let appAccent       = Color(.sRGB, red: 0.122, green: 0.627, blue: 0.400)
    static let appFieldBg      = Color(.sRGB, red: 0.886, green: 0.878, blue: 0.847)
    static let appSegSelected  = Color.white
    static let appOkText       = Color(.sRGB, red: 0.122, green: 0.616, blue: 0.373)
    static let appOkBg         = Color(.sRGB, red: 0.122, green: 0.616, blue: 0.373, opacity: 0.13)
    static let appNeutText     = Color(.sRGB, red: 0.525, green: 0.518, blue: 0.494)
    static let appNeutBg       = Color(.sRGB, red: 0.471, green: 0.463, blue: 0.431, opacity: 0.14)
    static let appWarnText     = Color(.sRGB, red: 0.839, green: 0.271, blue: 0.231)
    static let appWarnBg       = Color(.sRGB, red: 0.839, green: 0.271, blue: 0.231, opacity: 0.12)
    static let appTabBg        = Color(.sRGB, red: 0.925, green: 0.918, blue: 0.894, opacity: 0.90)
    static let appTabInactive  = Color(.sRGB, red: 0.643, green: 0.635, blue: 0.604)
    static let appSheetBg      = Color(.sRGB, red: 0.925, green: 0.918, blue: 0.894)
    static let appSheetCard    = Color.white
    static let appDisabledBg   = Color(.sRGB, red: 0.471, green: 0.463, blue: 0.431, opacity: 0.16)
    static let appDisabledText = Color(.sRGB, red: 0.102, green: 0.102, blue: 0.094, opacity: 0.32)
#endif
}
