import Foundation

class PixivService {

    static let shared = PixivService()

    func fetchBookmarks(
        userId: String,
        cookie: String,
        offset: Int = 0,
        limit: Int = 48
    ) async throws -> PixivResponse {
        let urlString = "https://www.pixiv.net/ajax/user/\(userId)/illusts/bookmarks?tag=&offset=\(offset)&limit=\(limit)&rest=show&lang=ja"
        guard let url = URL(string: urlString) else {
            throw PixivError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("same-origin", forHTTPHeaderField: "Sec-Fetch-Site")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("cors", forHTTPHeaderField: "Sec-Fetch-Mode")
        request.setValue("ja", forHTTPHeaderField: "Accept-Language")
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.3.1 Safari/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue(
            "https://www.pixiv.net/users/\(userId)/bookmarks/artworks",
            forHTTPHeaderField: "Referer"
        )
        request.setValue("empty", forHTTPHeaderField: "Sec-Fetch-Dest")
        request.setValue(cookie, forHTTPHeaderField: "Cookie")
        request.setValue(userId, forHTTPHeaderField: "x-user-id")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PixivError.requestFailed
        }

        let decoder = JSONDecoder()
        let pixivResponse = try decoder.decode(PixivResponse.self, from: data)

        if pixivResponse.error {
            throw PixivError.apiError(pixivResponse.message)
        }

        return pixivResponse
    }
}

enum PixivError: LocalizedError {
    case invalidURL
    case requestFailed
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "Error.InvalidURL")
        case .requestFailed:
            return String(localized: "Error.RequestFailed")
        case .apiError(let message):
            return String(localized: "Error.APIError \(message)")
        }
    }
}
