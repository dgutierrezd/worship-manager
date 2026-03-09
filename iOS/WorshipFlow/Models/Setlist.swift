import Foundation

struct Setlist: Codable, Identifiable {
    let id: String
    var bandId: String?
    var name: String
    var date: String?
    var notes: String?
    var isTemplate: Bool?
    var createdBy: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, date, notes
        case bandId = "band_id"
        case isTemplate = "is_template"
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
