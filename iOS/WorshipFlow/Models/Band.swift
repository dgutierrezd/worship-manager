import Foundation

struct Band: Codable, Identifiable {
    let id: String
    var name: String
    var church: String?
    var inviteCode: String
    var avatarColor: String
    var avatarEmoji: String
    var avatarUrl: String?
    var createdBy: String?
    var createdAt: String?
    var myRole: String?
    var memberCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, church
        case inviteCode = "invite_code"
        case avatarColor = "avatar_color"
        case avatarEmoji = "avatar_emoji"
        case avatarUrl = "avatar_url"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case myRole = "my_role"
        case memberCount = "member_count"
    }

    var isLeader: Bool { myRole == "leader" }
}
