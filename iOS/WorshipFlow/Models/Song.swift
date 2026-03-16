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
    var lyrics: String?
    var tags: [String]?
    var theme: String?
    var youtubeUrl: String?
    var spotifyUrl: String?
    var createdBy: String?
    var createdAt: String?
    var timesUsed: Int?
    var lastUsedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, artist, notes, lyrics, tags, theme
        case bandId = "band_id"
        case defaultKey = "default_key"
        case tempoBpm = "tempo_bpm"
        case durationSec = "duration_sec"
        case youtubeUrl = "youtube_url"
        case spotifyUrl = "spotify_url"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case timesUsed = "times_used"
        case lastUsedAt = "last_used_at"
    }

    var formattedDuration: String? {
        guard let sec = durationSec else { return nil }
        let m = sec / 60
        let s = sec % 60
        return String(format: "%d:%02d", m, s)
    }

    /// Returns all musical keys in chromatic order for transpose UI
    static let musicalKeys = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]

    /// Transpose a key string by a given number of semitone steps
    static func transpose(key: String, steps: Int) -> String {
        guard let idx = musicalKeys.firstIndex(of: key) else { return key }
        let newIdx = ((idx + steps) % 12 + 12) % 12
        return musicalKeys[newIdx]
    }
}
