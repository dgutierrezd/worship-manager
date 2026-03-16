import Foundation

// MARK: - Service-level member assignment

struct ServiceAssignment: Codable, Identifiable {
    let id: String
    var setlistId: String
    var userId: String
    var role: String          // "leader", "musician", "vocalist", "tech", "volunteer"
    var instrument: String?
    var notes: String?
    var status: String?       // "confirmed", "pending", "declined"
    var member: Member?

    enum CodingKeys: String, CodingKey {
        case id, role, instrument, notes, status, member
        case setlistId = "setlist_id"
        case userId    = "user_id"
    }

    var roleDisplay: String {
        switch role {
        case "leader":    return "Worship Leader"
        case "musician":  return instrument?.capitalized ?? "Musician"
        case "vocalist":  return "Vocalist"
        case "tech":      return "Tech"
        case "volunteer": return "Volunteer"
        default:          return role.capitalized
        }
    }

    var statusColor: StatusColor {
        switch status {
        case "confirmed": return .going
        case "declined":  return .no
        default:          return .maybe
        }
    }

    enum StatusColor { case going, maybe, no }
}

// MARK: - Per-song assignment within a service

struct SongAssignment: Codable, Identifiable {
    let id: String
    var setlistSongId: String?
    var userId: String?
    var instrument: String?
    var notes: String?
    var member: Member?

    enum CodingKeys: String, CodingKey {
        case id, instrument, notes, member
        case setlistSongId = "setlist_song_id"
        case userId        = "user_id"
    }
}
