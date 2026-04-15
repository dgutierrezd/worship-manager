import Foundation

/// One row from the user's notification inbox. Mirrors backend `notifications` table.
struct AppNotification: Codable, Identifiable {
    let id: String
    let userId: String
    let bandId: String?
    let kind: String          // "service" | "rehearsal" | "system"
    let title: String
    let body: String
    let entityId: String?     // setlist_id when service, rehearsal_id when rehearsal
    let readAt: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, kind, title, body
        case userId    = "user_id"
        case bandId    = "band_id"
        case entityId  = "entity_id"
        case readAt    = "read_at"
        case createdAt = "created_at"
    }

    var isRead: Bool { readAt != nil }

    /// "2 min ago", "Yesterday", "Mar 12", etc.
    var relativeTime: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = iso.date(from: createdAt)
            ?? ISO8601DateFormatter().date(from: createdAt)
            ?? Date()
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }

    var iconName: String {
        switch kind {
        case "service":   return "music.note.list"
        case "rehearsal": return "calendar"
        default:          return "bell.fill"
        }
    }
}
