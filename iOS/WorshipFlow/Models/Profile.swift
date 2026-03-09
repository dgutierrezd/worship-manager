import Foundation

struct Profile: Codable {
    let id: String
    var fullName: String
    var avatarUrl: String?
    var instrument: String?
    var language: String?

    enum CodingKeys: String, CodingKey {
        case id, instrument, language
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
    }
}
