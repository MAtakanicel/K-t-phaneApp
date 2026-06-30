import SwiftUI

// §5.7 — Bottom sheet iskelet: sheetBg zemin, üst köşe 22px, grabber + ortalı başlık + kapat (×).
// İçerik sheetCard kartlarında sunulur. Kullanım: .sheet(isPresented:) { ConfirmSheet(...) }
struct ConfirmSheet<Content: View>: View {
    let title: String
    @Binding var isPresented: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appSheetBg.ignoresSafeArea()
                ScrollView {
                    content()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.appTertiary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
        .presentationCornerRadius(22)
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.appSheetBg)
    }
}

// MARK: - Kart kabı (içerik bloklarını sheetCard rengiyle sarmak için)

struct SheetCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .background(Color.appSheetCard, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    struct Demo: View {
        @State private var show = true
        var body: some View {
            Button("Sheet'i aç") { show = true }
                .sheet(isPresented: $show) {
                    ConfirmSheet(title: "Ödünç Ver", isPresented: $show) {
                        SheetCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Suç ve Ceza").font(.listRowTitle)
                                    .foregroundStyle(Color.appLabel).padding()
                            }
                        }
                        PrimaryButton(title: "Onayla") { show = false }
                    }
                }
        }
    }
    return Demo()
}
