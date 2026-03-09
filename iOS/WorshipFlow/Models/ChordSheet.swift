import Foundation

struct ChordSheet: Codable, Identifiable {
    let id: String
    var songId: String?
    var instrument: String?
    var title: String
    var content: String
    var createdBy: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, instrument, title, content
        case songId = "song_id"
        case createdBy = "created_by"
        case updatedAt = "updated_at"
    }
}
