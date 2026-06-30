import SwiftUI

struct DashboardTab: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.appTertiary)
                    Text("Özet")
                        .font(.listRowTitle)
                        .foregroundStyle(Color.appSecondary)
                    Text("Faz 8'de doldurulacak")
                        .font(.listRowSubtitle)
                        .foregroundStyle(Color.appTertiary)
                }
            }
            .navigationTitle("Özet")
        }
    }
}

#Preview("Light") { DashboardTab() }
#Preview("Dark")  { DashboardTab().preferredColorScheme(.dark) }
