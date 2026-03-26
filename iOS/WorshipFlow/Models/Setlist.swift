import Foundation

struct Setlist: Codable, Identifiable {
    let id: String
    var bandId: String?
    var name: String
    var date: String?
    var time: String?
    var notes: String?
    var isTemplate: Bool?
    var serviceType: String?
    var location: String?
    var theme: String?
    var createdBy: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, date, time, notes, location, theme
        case bandId = "band_id"
        case isTemplate = "is_template"
        case serviceType = "service_type"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }

    var parsedDate: Date? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }

    var formattedDate: String? {
        guard let d = parsedDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: d)
    }

    var formattedTime: String? {
        guard let time else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        guard let t = formatter.date(from: time) else { return nil }
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: t)
    }

    var scheduledDate: Date? {
        guard let d = parsedDate else { return nil }
        guard let time, !time.isEmpty else { return d }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: "\(date!) \(time)") ?? d
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
