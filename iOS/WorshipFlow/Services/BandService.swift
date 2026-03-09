import Foundation

enum BandService {
    static func myBands() async throws -> [Band] {
        try await APIClient.shared.get("/bands/my")
    }

    static func getBand(id: String) async throws -> Band {
        try await APIClient.shared.get("/bands/\(id)")
    }

    static func createBand(name: String, church: String?, emoji: String, color: String) async throws -> Band {
        var body: [String: Any] = [
            "name": name,
            "avatar_emoji": emoji,
            "avatar_color": color
        ]
        if let church, !church.isEmpty { body["church"] = church }
        return try await APIClient.shared.post("/bands", body: body)
    }

    static func joinBand(code: String) async throws -> Band {
        try await APIClient.shared.post("/bands/join", body: ["code": code])
    }

    static func updateBand(id: String, name: String?, church: String?, emoji: String?, color: String?) async throws -> Band {
        var body: [String: Any] = [:]
        if let name { body["name"] = name }
        if let church { body["church"] = church }
        if let emoji { body["avatar_emoji"] = emoji }
        if let color { body["avatar_color"] = color }
        return try await APIClient.shared.put("/bands/\(id)", body: body)
    }

    static func uploadAvatar(bandId: String, imageData: Data) async throws -> Band {
        try await APIClient.shared.uploadImage("/bands/\(bandId)/avatar", imageData: imageData)
    }

    static func deleteBand(id: String) async throws {
        try await APIClient.shared.delete("/bands/\(id)")
    }

    static func regenerateCode(bandId: String) async throws -> Band {
        try await APIClient.shared.post("/bands/\(bandId)/regenerate-code")
    }

    // Members
    static func getMembers(bandId: String) async throws -> [Member] {
        try await APIClient.shared.get("/bands/\(bandId)/members")
    }

    static func removeMember(bandId: String, userId: String) async throws {
        try await APIClient.shared.delete("/bands/\(bandId)/members/\(userId)")
    }

    static func updateMemberRole(bandId: String, userId: String, role: String) async throws -> MessageResponse {
        try await APIClient.shared.patch("/bands/\(bandId)/members/\(userId)", body: ["role": role])
    }
}
