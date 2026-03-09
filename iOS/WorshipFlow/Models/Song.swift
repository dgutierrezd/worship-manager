import Foundation

struct Song: Codable, Identifiable {
    let id: String
    var bandId: String?
    var title: String
    var artist: String?
    var defaultKey: String?
    var tempoBpm: Int?
    var durationSec: Int?
    var notes: String?
    var youtubeUrl: String?
    var spotifyUrl: String?
    var createdBy: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, artist, notes
        case bandId = "band_id"
        case defaultKey = "default_key"
        case tempoBpm = "tempo_bpm"
        case durationSec = "duration_sec"
        case youtubeUrl = "youtube_url"
        case spotifyUrl = "spotify_url"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }

    var formattedDuration: String? {
        guard let sec = durationSec else { return nil }
        let m = sec / 60
        let s = sec % 60
        return String(format: "%d:%02d", m, s)
    }
}
