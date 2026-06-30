import SwiftUI

struct SettingsTab: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                VStack(spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.appTertiary)
                    Text("Ayarlar")
                        .font(.listRowTitle)
                        .foregroundStyle(Color.appSecondary)
                    Text("Faz 8'de doldurulacak")
                        .font(.listRowSubtitle)
                        .foregroundStyle(Color.appTertiary)
                }
            }
            .navigationTitle("Ayarlar")
        }
    }
}

#Preview("Light") { SettingsTab() }
#Preview("Dark")  { SettingsTab().preferredColorScheme(.dark) }
