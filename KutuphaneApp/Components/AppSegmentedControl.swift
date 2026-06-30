import SwiftUI

// §5.5 — Özelleştirilmiş segmented control.
// fieldBg track, radius 9px, seçili: segSelected + hafif gölge.
struct AppSegmentedControl: View {
    let options: [String]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options.indices, id: \.self) { idx in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selection = idx }
                } label: {
                    Text(options[idx])
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selection == idx ? Color.appLabel : Color.appSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(selection == idx ? Color.appSegSelected : Color.clear)
                                .shadow(
                                    color: .black.opacity(selection == idx ? 0.07 : 0),
                                    radius: 3, y: 1
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Color.appFieldBg, in: RoundedRectangle(cornerRadius: 9))
    }
}

#Preview {
    struct Demo: View {
        @State private var sel = 0
        var body: some View {
            AppSegmentedControl(options: ["Hepsi", "Rafta", "Ödünçte"], selection: $sel)
                .padding()
                .background(Color.appBg)
        }
    }
    return Demo()
}
