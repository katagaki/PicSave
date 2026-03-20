import Foundation

struct PixivResponseBody: Codable, Sendable {
    let works: [PixivWork]
    let total: Int
}
