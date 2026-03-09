import Foundation

struct Rehearsal: Codable, Identifiable {
    let id: String
    var bandId: String?
    var setlistId: String?
    var title: String
    var location: String?
    var scheduledAt: String
    var notes: String?
    var createdBy: String?
    var createdAt: String?
    var setlists: SetlistRef?

    enum CodingKeys: String, CodingKey {
        case id, title, location, notes, setlists
        case bandId = "band_id"
        case setlistId = "setlist_id"
        case scheduledAt = "scheduled_at"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }

    struct SetlistRef: Codable {
        let name: String
    }

    var scheduledDate: Date? {
        ISO8601DateFormatter().date(from: scheduledAt)
    }

    var formattedDate: String {
        guard let date = scheduledDate else { return scheduledAt }
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: date)
    }

    var formattedTime: String {
        guard let date = scheduledDate else { return "" }
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    var isPast: Bool {
        guard let date = scheduledDate else { return false }
        return date < Date()
    }
}

struct RehearsalRSVP: Codable {
    var rehearsalId: String?
    var userId: String?
    var status: String
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case status
        case rehearsalId = "rehearsal_id"
        case userId = "user_id"
        case updatedAt = "updated_at"
    }
}
