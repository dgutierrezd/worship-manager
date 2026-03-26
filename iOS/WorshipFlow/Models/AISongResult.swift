import Foundation

// MARK: - AI Song Import Models

struct AISongResult: Codable, Identifiable {
    // Computed id for Identifiable (not encoded/decoded)
    var id: String { title + (artist ?? "") }

    let found: Bool
    let title: String
    let artist: String?
    let defaultKey: String?
    let tempoBpm: Int?
    let durationSec: Int?
    let lyrics: String?
    let theme: String?
    let youtubeUrl: String?
    let spotifyUrl: String?
    let chordSections: [AIChordSection]?

    enum CodingKeys: String, CodingKey {
        case found, title, artist, lyrics, theme
        case defaultKey  = "default_key"
        case tempoBpm    = "tempo_bpm"
        case durationSec = "duration_sec"
        case youtubeUrl  = "youtube_url"
        case spotifyUrl  = "spotify_url"
        case chordSections = "chord_sections"
    }
}

struct AIChordSection: Codable {
    let name: String
    let chords: [AIChordEntry]
}

struct AIChordEntry: Codable {
    let degree: Int
    let modifier: String?
}
