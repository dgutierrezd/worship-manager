import Foundation

// MARK: - AI Song Import Models
//
// These models represent the structured data Claude returns for each song.
// They map 1-to-1 with the JSON schema specified in ClaudeService's prompt.

struct AISongResult: Codable, Identifiable {

    // Computed stable id for Identifiable conformance — not encoded/decoded
    var id: String { title + (artist ?? "") }

    // MARK: Core fields
    let found:       Bool
    let title:       String
    let artist:      String?
    let defaultKey:  String?
    let tempoBpm:    Int?
    let durationSec: Int?
    let lyrics:      String?
    let theme:       String?
    let youtubeUrl:  String?
    let spotifyUrl:  String?
    let chordSections: [AIChordSection]?

    // MARK: CodingKeys — map camelCase ↔ snake_case JSON keys
    enum CodingKeys: String, CodingKey {
        case found, title, artist, lyrics, theme
        case defaultKey    = "default_key"
        case tempoBpm      = "tempo_bpm"
        case durationSec   = "duration_sec"
        case youtubeUrl    = "youtube_url"
        case spotifyUrl    = "spotify_url"
        case chordSections = "chord_sections"
    }
}

// MARK: - Chord Section

struct AIChordSection: Codable {
    /// Display name of the section — e.g. "Verse", "Chorus", "Bridge"
    let name: String
    /// Ordered list of chords in Nashville Number System notation
    let chords: [AIChordEntry]
}

// MARK: - Chord Entry (Nashville Number System)

struct AIChordEntry: Codable {
    /// Scale degree 1–7
    let degree: Int
    /// Quality modifier: null = major, "m" = minor, "7" = dom7, "maj7", "sus2", "sus4", "dim", "aug", "add9"
    let modifier: String?
}

// MARK: - Mapping helpers

extension AISongResult {

    /// Convert an `AIChordSection` array into a `ChordProgression` (the app's native model)
    /// so it can be saved as a chord sheet.
    func toChordProgression() -> ChordProgression? {
        guard let sections = chordSections, !sections.isEmpty else { return nil }

        let mapped = sections.map { section -> ChordSection in
            let entries = section.chords.map { entry -> ChordEntry in
                ChordEntry(degree: entry.degree, isPass: false, modifier: entry.modifier)
            }
            return ChordSection(name: section.name, chords: entries)
        }

        return ChordProgression(sections: mapped)
    }

    /// Returns a human-readable chord summary for display in the result card.
    var chordSummary: String? {
        guard let sections = chordSections, !sections.isEmpty else { return nil }
        return sections.map { "\($0.name) (\($0.chords.count))" }.joined(separator: "  ·  ")
    }

    /// Whether this song has usable chord data beyond just "found"
    var hasChords: Bool {
        (chordSections?.isEmpty == false) == true
    }

    /// Whether this song has lyrics
    var hasLyrics: Bool {
        lyrics?.isEmpty == false
    }
}
