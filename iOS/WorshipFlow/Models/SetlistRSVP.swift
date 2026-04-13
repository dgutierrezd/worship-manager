import Foundation

/// User's RSVP for a service (setlist). Mirrors `RehearsalRSVP`.
struct SetlistRSVP: Codable {
    var setlistId: String?
    var userId: String?
    var status: String
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case status
        case setlistId = "setlist_id"
        case userId = "user_id"
        case updatedAt = "updated_at"
    }
}
