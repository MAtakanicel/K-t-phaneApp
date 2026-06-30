import SwiftUI

// §5.3 — Üye avatarı: fieldBg daire + baş harfler.
struct Avatar: View {
    let name: String
    var size: CGFloat = 40

    private var initials: String {
        name.components(separatedBy: .whitespaces)
            .prefix(2)
            .compactMap { $0.first.map { String($0).uppercased() } }
            .joined()
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.appFieldBg)
            Text(initials)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appSecondary)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 12) {
        Avatar(name: "Ahmet Yılmaz")
        Avatar(name: "Zeynep Kaya", size: 52)
        Avatar(name: "X")
    }
    .padding()
    .background(Color.appBg)
}
