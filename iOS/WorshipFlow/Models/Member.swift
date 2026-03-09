import Foundation

struct Member: Codable, Identifiable {
    let id: String
    var fullName: String
    var avatarUrl: String?
    var instrument: String?
    var role: String
    var joinedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, role, instrument
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case joinedAt = "joined_at"
    }

    var isLeader: Bool { role == "leader" }

    var instrumentIcon: String {
        switch instrument?.lowercased() {
        case "guitar": return "guitars"
        case "bass": return "guitars"
        case "drums": return "drum"
        case "keys", "piano", "keyboard": return "pianokeys"
        case "vocals", "voice": return "mic"
        default: return "music.note"
        }
    }
}
