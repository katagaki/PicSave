import Foundation

struct PixivWork: Codable, Identifiable, Sendable {
    let id: FlexibleString
    let title: String
    let illustType: Int
    let xRestrict: Int
    let url: String
    let tags: [String]
    let userId: FlexibleString
    let userName: String
    let width: Int
    let height: Int
    let pageCount: Int
    let bookmarkData: BookmarkData?
    let createDate: String
    let updateDate: String
    let aiType: Int
    let profileImageUrl: String?
}
