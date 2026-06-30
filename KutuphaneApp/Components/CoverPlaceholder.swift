import SwiftUI

// §5.3 / §9 — Kitap kapak placeholder: sıcak koyu ton + sol sırt çizgisi + baş harf.
// Gerçek kapak URL'si gelince Image() ile değiştirilir; bu her zaman fallback.
struct CoverPlaceholder: View {
    let title: String
    var width: CGFloat = 42
    var height: CGFloat = 58

    private var initial: String {
        title.first.map { String($0).uppercased() } ?? "?"
    }

    // Sabit sıcak/koyu ton paleti — greige temayla uyumlu
    private static let tones: [Color] = [
        Color(.sRGB, red: 0.29, green: 0.37, blue: 0.47),
        Color(.sRGB, red: 0.42, green: 0.31, blue: 0.46),
        Color(.sRGB, red: 0.33, green: 0.44, blue: 0.38),
        Color(.sRGB, red: 0.47, green: 0.35, blue: 0.27),
        Color(.sRGB, red: 0.27, green: 0.42, blue: 0.44),
        Color(.sRGB, red: 0.44, green: 0.39, blue: 0.31),
        Color(.sRGB, red: 0.38, green: 0.30, blue: 0.46),
        Color(.sRGB, red: 0.31, green: 0.44, blue: 0.35),
    ]

    private var tone: Color {
        let idx = abs(title.hashValue) % Self.tones.count
        return Self.tones[idx]
    }

    var body: some View {
        ZStack(alignment: .leading) {
            tone
            // Sol sırt çizgisi
            Rectangle()
                .fill(Color.white.opacity(0.18))
                .frame(width: max(3, width * 0.07))
            // Baş harf — ortada
            Text(initial)
                .font(.caption.bold())
                .foregroundStyle(Color.white.opacity(0.85))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

// Kompakt boyut kolaylığı
extension CoverPlaceholder {
    static func compact(title: String) -> CoverPlaceholder {
        CoverPlaceholder(title: title, width: 34, height: 46)
    }
}

// MARK: - BookCover (AsyncImage + placeholder fallback)
// URL varsa AsyncImage; yüklenene kadar CoverPlaceholder; başarısızlıkta da CoverPlaceholder.
struct BookCover: View {
    let title: String
    var coverURL: String? = nil
    var width: CGFloat = 42
    var height: CGFloat = 58

    var body: some View {
        if let coverURL,
           let trimmed = coverURL.trimmingCharacters(in: .whitespacesAndNewlines)
                .nilIfEmpty,
           let url = URL(string: trimmed) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    CoverPlaceholder(title: title, width: width, height: height)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: height)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                case .failure:
                    CoverPlaceholder(title: title, width: width, height: height)
                @unknown default:
                    CoverPlaceholder(title: title, width: width, height: height)
                }
            }
            .frame(width: width, height: height)
        } else {
            CoverPlaceholder(title: title, width: width, height: height)
        }
    }

    static func compact(title: String, coverURL: String? = nil) -> BookCover {
        BookCover(title: title, coverURL: coverURL, width: 34, height: 46)
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

#Preview {
    HStack(spacing: 12) {
        CoverPlaceholder(title: "Suç ve Ceza")
        CoverPlaceholder(title: "Dune")
        CoverPlaceholder(title: "Şeker Portakalı")
        CoverPlaceholder.compact(title: "1984")
    }
    .padding()
    .background(Color.appBg)
}
