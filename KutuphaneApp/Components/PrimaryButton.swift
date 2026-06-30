import SwiftUI

// §5.9 — Tam genişlik birincil buton, 50px yükseklik, radius 14px.
// Pasif durumda: disabledBg zemin + disabledText renk.
struct PrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.primaryButton)
                .foregroundStyle(isEnabled ? Color.white : Color.appDisabledText)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    isEnabled ? Color.appAccent : Color.appDisabledBg,
                    in: RoundedRectangle(cornerRadius: 14)
                )
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    VStack(spacing: 12) {
        PrimaryButton(title: "Ödünç Ver") { }
        PrimaryButton(title: "Onayla", isEnabled: false) { }
        PrimaryButton(title: "İade Al") { }
    }
    .padding()
    .background(Color.appBg)
}
