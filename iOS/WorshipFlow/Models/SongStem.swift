import Foundation

/// A single multitrack stem attached to a song.
/// Audio is NOT hosted by us — `url` points to the user's own cloud
/// (Dropbox, Google Drive, OneDrive, direct web host, etc.).
struct SongStem: Codable, Identifiable, Equatable, Hashable {
    let id: String
    var songId: String
    var bandId: String
    var kind: String
    var label: String
    var url: String
    var position: Int?

    enum CodingKeys: String, CodingKey {
        case id, kind, label, url, position
        case songId = "song_id"
        case bandId = "band_id"
    }

    // MARK: - Kinds

    /// User-facing kinds. Drive icon + color in the stem list.
    static let kinds: [String] = [
        "click", "guide", "drums", "bass", "keys", "pad", "vocal", "guitar", "other",
    ]

    static func displayName(forKind kind: String) -> String {
        switch kind {
        case "click":  return "Click"
        case "guide":  return "Guide"
        case "drums":  return "Drums"
        case "bass":   return "Bass"
        case "keys":   return "Keys"
        case "pad":    return "Pad"
        case "vocal":  return "Vocal"
        case "guitar": return "Guitar"
        default:       return "Other"
        }
    }

    static func icon(forKind kind: String) -> String {
        switch kind {
        case "click":  return "metronome"
        case "guide":  return "waveform"
        case "drums":  return "drum.fill"
        case "bass":   return "guitars.fill"
        case "keys":   return "pianokeys"
        case "pad":    return "wave.3.right"
        case "vocal":  return "mic.fill"
        case "guitar": return "guitars"
        default:       return "music.note"
        }
    }
}
