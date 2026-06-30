import Foundation

// Faz 8 — Ayarlar canlı kaynağı.
// AppRoot bir kez yaratır, observe()'i başlatır; her snapshot
// `LendingSettings.current`'a yansıtılır → tüm türetilmiş hesaplar
// (gecikme, limit, dueDate) tek kaynaktan akar (D6).
@MainActor
@Observable
final class SettingsStore {
    var settings: LendingSettings = .default
    var isLoading: Bool = true
    var errorMessage: String? = nil

    private let repo: any SettingsRepository

    init(repo: any SettingsRepository) {
        self.repo = repo
    }

    func observe() async {
        isLoading = true
        errorMessage = nil
        for await fresh in repo.observeSettings() {
            settings = fresh
            LendingSettings.current = fresh
            isLoading = false
        }
    }

    func update(_ new: LendingSettings) async {
        do {
            try await repo.updateSettings(new)
            // observeSettings akışı da yeni snapshot getirir; UI'ı bekletmeden hemen güncelle.
            settings = new
            LendingSettings.current = new
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
