import Foundation

/// REST wrapper for the notification inbox endpoints.
enum NotificationInboxService {
    static func list(unreadOnly: Bool = false, limit: Int = 50) async throws -> [AppNotification] {
        var path = "/notifications?limit=\(limit)"
        if unreadOnly { path += "&unread=true" }
        return try await APIClient.shared.get(path)
    }

    struct CountResponse: Decodable { let count: Int }
    static func unreadCount() async throws -> Int {
        let r: CountResponse = try await APIClient.shared.get("/notifications/unread-count")
        return r.count
    }

    static func markRead(id: String) async throws {
        let _: MessageResponse = try await APIClient.shared.post("/notifications/\(id)/read", body: [:])
    }

    static func markAllRead() async throws {
        let _: MessageResponse = try await APIClient.shared.post("/notifications/read-all", body: [:])
    }
}
