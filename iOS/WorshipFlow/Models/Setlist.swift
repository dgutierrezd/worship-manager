import Foundation

struct Setlist: Codable, Identifiable {
    let id: String
    var bandId: String?
    var name: String
    var date: String?
    var notes: String?
    var isTemplate: Bool?
    var serviceType: String?
    var location: String?
    var theme: String?
    var createdBy: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, date, notes, location, theme
        case bandId = "band_id"
        case isTemplate = "is_template"
        case serviceType = "service_type"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }

    var formattedDate: String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let d = formatter.date(from: date) else { return nil }
        formatter.dateStyle = .medium
        return formatter.string(from: d)
    }

    var isUpcoming: Bool {
        guard let date else { return true }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let d = formatter.date(from: date) else { return true }
        return d >= Calendar.current.startOfDay(for: Date())
    }

    var serviceTypeDisplay: String {
        switch serviceType {
        case "sunday_morning":  return "Sunday Morning"
        case "sunday_evening":  return "Sunday Evening"
        case "wednesday":       return "Wednesday"
        case "special":         return "Special Event"
        default:                return "Service"
        }
    }

    var serviceTypeIcon: String {
        switch serviceType {
        case "sunday_morning":  return "sun.max.fill"
        case "sunday_evening":  return "moon.stars.fill"
        case "wednesday":       return "calendar.badge.clock"
        case "special":         return "star.fill"
        default:                return "music.note.list"
        }
    }
}

struct SetlistSong: Codable, Identifiable {
    let id: String
    var setlistId: String?
    var songId: String?
    var position: Int
    var keyOverride: String?
    var notes: String?
    var songs: Song?

    enum CodingKeys: String, CodingKey {
        case id, position, notes, songs
        case setlistId = "setlist_id"
        case songId = "song_id"
        case keyOverride = "key_override"
    }

    var displayKey: String? { keyOverride ?? songs?.defaultKey }
}
