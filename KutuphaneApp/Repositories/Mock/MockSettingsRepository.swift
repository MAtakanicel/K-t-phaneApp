import Foundation

final class MockSettingsRepository: SettingsRepository {
    private(set) var settings: LendingSettings
    private var continuation: AsyncStream<LendingSettings>.Continuation?

    init(settings: LendingSettings = .default) {
        self.settings = settings
    }

    func observeSettings() -> AsyncStream<LendingSettings> {
        AsyncStream { [weak self] cont in
            guard let self else { return }
            self.continuation = cont
            cont.yield(self.settings)
        }
    }

    func fetchSettings() async throws -> LendingSettings { settings }

    func updateSettings(_ settings: LendingSettings) async throws {
        self.settings = settings
        continuation?.yield(settings)
    }
}
