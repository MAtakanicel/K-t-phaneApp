import Foundation

// D6: Gecikme/iade süresi tek kaynaktan türetilir. Faz 8.
// `LendingSettings.current` tüm uygulamadaki türetilmiş hesapların okuduğu MainActor snapshot'ı;
// `SettingsStore` Firestore observer'ı bu snapshot'ı günceller.
struct LendingSettings: Codable, Equatable, Sendable {
    var libraryName: String
    var staffName: String
    var loanLimit: Int           // Üye başına aktif ödünç limiti (default 3)
    var loanDurationDays: Int    // Ödünç süresi (default 15 gün)
    var overdueAlertsEnabled: Bool

    static let `default` = LendingSettings(
        libraryName: "",
        staffName: "",
        loanLimit: 3,
        loanDurationDays: 15,
        overdueAlertsEnabled: true
    )

    // MARK: - Türetilmiş hesaplar (D6: tek kaynak)

    func dueDate(from borrowDate: Date) -> Date {
        Calendar.current.date(byAdding: .day,
                              value: loanDurationDays,
                              to: borrowDate) ?? borrowDate
    }

    /// Pozitif gün sayısı döndürür; gecikme yoksa nil.
    func overdueDays(from borrowDate: Date?, now: Date = .now) -> Int? {
        guard let borrowDate else { return nil }
        let due = dueDate(from: borrowDate)
        let days = Calendar.current.dateComponents([.day], from: due, to: now).day ?? 0
        return days > 0 ? days : nil
    }
}

// MARK: - MainActor snapshot
// VM'ler bunu okur; SettingsStore observe akışında günceller.
// Preview'lerde override etmek için doğrudan atanabilir.
extension LendingSettings {
    @MainActor static var current: LendingSettings = .default
}
