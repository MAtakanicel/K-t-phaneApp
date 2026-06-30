import Foundation
import FirebaseFirestore

// MARK: - Protokol

protocol SettingsRepository {
    /// Canlı dinleyici — settings/main dökümanı her değiştiğinde yeni snapshot yayınlar.
    /// Döküman yoksa `LendingSettings.default` yayınlar.
    func observeSettings() -> AsyncStream<LendingSettings>
    func fetchSettings() async throws -> LendingSettings
    func updateSettings(_ settings: LendingSettings) async throws
}

// MARK: - Firestore implementasyonu

final class FirestoreSettingsRepository: SettingsRepository {
    private let docRef = Firestore.firestore().collection("settings").document("main")

    func observeSettings() -> AsyncStream<LendingSettings> {
        AsyncStream { continuation in
            let listener = docRef.addSnapshotListener { snapshot, _ in
                let settings = (try? snapshot?.data(as: LendingSettings.self))
                    ?? .default
                continuation.yield(settings)
            }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func fetchSettings() async throws -> LendingSettings {
        let snap = try await docRef.getDocument()
        if snap.exists {
            return (try? snap.data(as: LendingSettings.self)) ?? .default
        }
        return .default
    }

    func updateSettings(_ settings: LendingSettings) async throws {
        try docRef.setData(from: settings, merge: false)
    }
}
