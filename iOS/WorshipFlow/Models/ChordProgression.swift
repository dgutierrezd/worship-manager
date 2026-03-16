import Foundation

// MARK: - Harmonic Function

enum HarmonicFunction {
    case tonic        // I, iii, vi  — stable, home feeling
    case subdominant  // ii, IV      — movement, pre-dominant
    case dominant     // V, vii°     — tension, wants resolution
}

// MARK: - Chord Entry (a single degree in a section)

struct ChordEntry: Codable, Identifiable, Equatable {
    var id: UUID
    var degree: Int        // 1–7 (Nashville Number System)
    var isPass: Bool       // true = shorter passing chord
    var modifier: String?  // "7", "maj7", "sus2", "sus4", "add9", "m7", "6", etc.

    init(degree: Int, isPass: Bool = false, modifier: String? = nil) {
        self.id = UUID()
        self.degree = degree
        self.isPass = isPass
        self.modifier = modifier
    }

    enum CodingKeys: String, CodingKey {
        case id, degree, modifier
        case isPass = "is_pass"
    }

    // MARK: - Music Theory

    /// Diatonic chord quality in a major key (standard: I ii iii IV V vi vii°)
    var diatonicQuality: ChordQuality {
        switch degree {
        case 1, 4, 5: return .major
        case 2, 3, 6: return .minor
        case 7:       return .diminished
        default:      return .major
        }
    }

    /// Harmonic function within a major key
    var harmonicFunction: HarmonicFunction {
        switch degree {
        case 1, 3, 6: return .tonic
        case 2, 4:    return .subdominant
        default:      return .dominant  // 5, 7
        }
    }

    /// Roman numeral with quality (e.g. "ii", "IV", "V", "vii°")
    var romanNumeral: String {
        switch degree {
        case 1: return "I"
        case 2: return "ii"
        case 3: return "iii"
        case 4: return "IV"
        case 5: return "V"
        case 6: return "vi"
        case 7: return "vii°"
        default: return "\(degree)"
        }
    }

    /// Full chord name when a key is provided (e.g. key=G → degree 4 = "C")
    /// Returns the degree number string when no key is available.
    func chordName(inKey key: String?) -> String {
        guard let key else { return "\(degree)" }
        // Major scale intervals in semitones from root: 0,2,4,5,7,9,11
        let offsets = [0, 2, 4, 5, 7, 9, 11]
        guard degree >= 1, degree <= 7 else { return "\(degree)" }
        let root = Song.transpose(key: key, steps: offsets[degree - 1])
        let qualitySuffix: String
        switch diatonicQuality {
        case .major:      qualitySuffix = ""
        case .minor:      qualitySuffix = "m"
        case .diminished: qualitySuffix = "dim"
        }
        let mod = modifier ?? ""
        return "\(root)\(qualitySuffix)\(mod)"
    }

    enum ChordQuality { case major, minor, diminished }
}

// MARK: - Chord Section (Verse, Chorus, Bridge, etc.)

struct ChordSection: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var chords: [ChordEntry]

    init(name: String, chords: [ChordEntry] = []) {
        self.id = UUID()
        self.name = name
        self.chords = chords
    }

    static let sectionNames = [
        "Intro", "Verse", "Pre-Chorus", "Chorus",
        "Bridge", "Instrumental", "Outro", "Tag"
    ]
}

// MARK: - Chord Progression (full song structure)

struct ChordProgression: Codable, Equatable {
    var sections: [ChordSection]

    init(sections: [ChordSection] = []) {
        self.sections = sections
    }

    func toJSON() -> String {
        guard let data = try? JSONEncoder().encode(self),
              let str = String(data: data, encoding: .utf8) else {
            return "{\"sections\":[]}"
        }
        return str
    }

    static func from(json: String) -> ChordProgression? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(ChordProgression.self, from: data)
    }
}

// MARK: - Editor Sheet Target (Identifiable wrapper — fixes SwiftUI sheet race condition)

struct ChordEditorTarget: Identifiable {
    let id: UUID = UUID()
    let sheet: ChordSheet?
}
