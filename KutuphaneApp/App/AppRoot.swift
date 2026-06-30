import SwiftUI

// D1: 4 düz sekme, merkez ⊕ yok. Ekleme ilgili ekranın sağ üst +/barkod butonuyla yapılır.
// Faz 8: SettingsStore burada yaratılır ve `.task`'la canlı dinlenir.
// Snapshot'lar `LendingSettings.current`'a yansır → tüm ekranlar tek kaynaktan okur (D6).
struct AppRoot: View {
    @State private var settingsStore = SettingsStore(repo: FirestoreSettingsRepository())

    var body: some View {
        TabView {
            DashboardTab()
                .tabItem { Label("Özet", systemImage: "chart.bar") }

            BooksTab()
                .tabItem { Label("Kitaplar", systemImage: "book") }

            MembersTab()
                .tabItem { Label("Üyeler", systemImage: "person.2") }

            SettingsTab(store: settingsStore)
                .tabItem { Label("Ayarlar", systemImage: "gearshape") }
        }
        .tint(Color.appAccent)
        .task { await settingsStore.observe() }
    }
}

#Preview("Light") {
    AppRoot()
}

#Preview("Dark") {
    AppRoot()
        .preferredColorScheme(.dark)
}
