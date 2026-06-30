import Foundation

// MARK: - Model

struct BookMetadata: Equatable {
    let title: String
    let authors: [String]
    let coverImageURL: String?
    let category: String?

    var authorsJoined: String {
        authors.joined(separator: ", ")
    }
}

// MARK: - Hata türleri

enum BookLookupError: Error, LocalizedError {
    case quotaExceeded         // HTTP 429 ya da 403 quotaExceeded
    case serverError(Int)      // diğer 4xx/5xx
    case transport(Error)      // URLSession transport hatası
    case malformedResponse

    var errorDescription: String? {
        switch self {
        case .quotaExceeded:        return "Google Books kota sınırına ulaşıldı."
        case .serverError(let s):   return "Sunucu hatası (\(s))."
        case .transport(let e):     return e.localizedDescription
        case .malformedResponse:    return "Yanıt çözümlenemedi."
        }
    }
}

// MARK: - Protokol

protocol BookLookupService {
    func lookup(isbn: String) async throws -> BookMetadata?
}

// MARK: - Google Books implementasyonu

// Teknik Tasarım §3.3 — API anahtarı gerektirmez, ücretsiz kotada kalır.
// D4: hata sessiz tutulmaz, çağırana iletilir → form elle girişe nazikçe düşer.
final class GoogleBooksLookupService: BookLookupService {
    private let session: URLSession
    private let timeout: TimeInterval
    private let apiKey: String?

    init(session: URLSession = .shared,
         timeout: TimeInterval = 8,
         apiKey: String? = GoogleBooksLookupService.apiKeyFromBundle()) {
        self.session = session
        self.timeout = timeout
        self.apiKey = apiKey
    }

    // Anahtar Secrets.xcconfig → Info.plist üzerinden gelir; runtime'da okunur.
    // Boş, "$(GOOGLE_BOOKS_API_KEY)" gibi yer tutucu, ya da yok ise nil döner.
    static func apiKeyFromBundle() -> String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "GoogleBooksAPIKey") as? String else {
            return nil
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("$(") else { return nil }
        return trimmed
    }

    func lookup(isbn: String) async throws -> BookMetadata? {
        let cleaned = isbn.filter { $0.isNumber || $0 == "X" || $0 == "x" }
        guard !cleaned.isEmpty,
              var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes") else {
            return nil
        }
        var items = [URLQueryItem(name: "q", value: "isbn:\(cleaned)")]
        if let apiKey {
            items.append(URLQueryItem(name: "key", value: apiKey))
        }
        components.queryItems = items
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "GET"

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw BookLookupError.transport(error)
        }

        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200..<300:
                break
            case 429:
                throw BookLookupError.quotaExceeded
            case 403:
                // Google quota exceeded de bazen 403 + "quotaExceeded" reason döner.
                if isQuotaResponse(data) {
                    throw BookLookupError.quotaExceeded
                }
                throw BookLookupError.serverError(http.statusCode)
            default:
                throw BookLookupError.serverError(http.statusCode)
            }
        }

        let payload: GoogleBooksResponse
        do {
            payload = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
        } catch {
            throw BookLookupError.malformedResponse
        }
        guard let info = payload.items?.first?.volumeInfo else { return nil }

        let rawCover = info.imageLinks?.bestAvailable
        print("[BookLookup] ISBN=\(cleaned) raw thumbnail=\(info.imageLinks?.thumbnail ?? "nil") smallThumbnail=\(info.imageLinks?.smallThumbnail ?? "nil") chosen=\(rawCover ?? "nil")")
        let cover = rawCover.map { httpsified($0) }
        if let cover { print("[BookLookup] normalized cover URL=\(cover)") }
        return BookMetadata(
            title: info.title ?? "",
            authors: info.authors ?? [],
            coverImageURL: cover,
            category: info.categories?.first
        )
    }

    private func isQuotaResponse(_ data: Data) -> Bool {
        guard let body = String(data: data, encoding: .utf8)?.lowercased() else { return false }
        return body.contains("quotaexceeded") || body.contains("ratelimitexceeded")
    }

    // Google bazen http://… döner; HTTPS'e zorla (ATS kuralları için).
    private func httpsified(_ raw: String) -> String {
        guard raw.hasPrefix("http://") else { return raw }
        return "https://" + raw.dropFirst("http://".count)
    }
}

// MARK: - Google Books JSON

private struct GoogleBooksResponse: Decodable {
    let items: [Item]?

    struct Item: Decodable {
        let volumeInfo: VolumeInfo
    }

    struct VolumeInfo: Decodable {
        let title: String?
        let authors: [String]?
        let categories: [String]?
        let imageLinks: ImageLinks?
    }

    struct ImageLinks: Decodable {
        let thumbnail: String?
        let smallThumbnail: String?

        var bestAvailable: String? { thumbnail ?? smallThumbnail }
    }
}

// MARK: - Mock (preview/test)

final class MockBookLookupService: BookLookupService {
    enum Behavior {
        case success(BookMetadata)
        case notFound
        case failure(Error)
    }

    var behavior: Behavior
    var delay: Duration = .milliseconds(150)

    init(behavior: Behavior = .success(.preview)) {
        self.behavior = behavior
    }

    func lookup(isbn: String) async throws -> BookMetadata? {
        try? await Task.sleep(for: delay)
        switch behavior {
        case .success(let meta): return meta
        case .notFound:          return nil
        case .failure(let err):  throw err
        }
    }
}

extension BookMetadata {
    static let preview = BookMetadata(
        title: "Suç ve Ceza",
        authors: ["Fyodor Dostoyevski"],
        coverImageURL: nil,
        category: "Roman"
    )
}
