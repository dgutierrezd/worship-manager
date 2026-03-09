import Foundation

// MARK: - Chord Entry (a single degree in a section)

struct ChordEntry: Codable, Identifiable, Equatable {
    var id: UUID
    var degree: Int       // 1–7 (Nashville numbers)
    var isPass: Bool      // false = full compás, true = passing chord

    init(degree: Int, isPass: Bool = false) {
        self.id = UUID()
        self.degree = degree
        self.isPass = isPass
    }

    enum CodingKeys: String, CodingKey {
        case id, degree
        case isPass = "is_pass"
    }
}

// MARK: - Chord Section (Verse, Chorus, etc.)

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

    /// Encode to JSON string for storing in the `content` field
    func toJSON() -> String {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return "{\"sections\":[]}"
        }
        return string
    }

    /// Decode from JSON string. Returns nil if content is not a valid progression.
    static func from(json: String) -> ChordProgression? {
        guard let data = json.data(using: .utf8),
              let prog = try? JSONDecoder().decode(ChordProgression.self, from: data) else {
            return nil
        }
        return prog
    }
}
