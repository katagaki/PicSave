import Foundation

struct PixivResponse: Codable, Sendable {
    let error: Bool
    let message: String
    let body: PixivResponseBody
}
