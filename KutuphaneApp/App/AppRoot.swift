import SwiftUI

// D1: 4 düz sekme, merkez ⊕ yok. Ekleme ilgili ekranın sağ üst +/barkod butonuyla yapılır.
struct AppRoot: View {
    var body: some View {
        TabView {
            DashboardTab()
                .tabItem { Label("Özet", systemImage: "chart.bar") }

            BooksTab()
                .tabItem { Label("Kitaplar", systemImage: "book") }

            MembersTab()
                .tabItem { Label("Üyeler", systemImage: "person.2") }

            SettingsTab()
                .tabItem { Label("Ayarlar", systemImage: "gearshape") }
        }
        .tint(Color.appAccent)
    }
}

#Preview("Light") {
    AppRoot()
}

#Preview("Dark") {
    AppRoot()
        .preferredColorScheme(.dark)
}
