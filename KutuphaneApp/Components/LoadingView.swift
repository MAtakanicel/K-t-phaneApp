import SwiftUI

// D4 — Yükleniyor durumu: accent renkte spinner + metin.
struct LoadingView: View {
    var message: String = "Yükleniyor…"

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Color.appAccent)
                .scaleEffect(1.2)
            Text(message)
                .font(.listRowSubtitle)
                .foregroundStyle(Color.appSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBg)
    }
}

#Preview {
    LoadingView()
}
