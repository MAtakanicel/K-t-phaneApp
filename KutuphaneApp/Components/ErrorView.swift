import SwiftUI

// D4 — Hata durumu: ikon + mesaj + "Tekrar Dene" butonu.
struct ErrorView: View {
    var message: String = "Bir sorun oluştu."
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(Color.appWarnText)

            Text(message)
                .font(.listRowSubtitle)
                .foregroundStyle(Color.appSecondary)
                .multilineTextAlignment(.center)

            if let retryAction {
                Button {
                    retryAction()
                } label: {
                    Text("Tekrar Dene")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color.appAccent)
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBg)
    }
}

#Preview {
    ErrorView(message: "Veriler yüklenemedi. İnternet bağlantını kontrol et.") { }
}
