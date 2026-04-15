import Foundation

enum RehearsalService {
    static func getRehearsals(bandId: String) async throws -> [Rehearsal] {
        try await APIClient.shared.get("/bands/\(bandId)/rehearsals")
    }

    static func createRehearsal(bandId: String, title: String, location: String?, scheduledAt: String, notes: String?, setlistId: String?) async throws -> Rehearsal {
        var body: [String: Any] = [
            "title": title,
            "scheduled_at": scheduledAt
        ]
        if let location, !location.isEmpty { body["location"] = location }
        if let notes, !notes.isEmpty { body["notes"] = notes }
        if let setlistId { body["setlist_id"] = setlistId }
        return try await APIClient.shared.post("/bands/\(bandId)/rehearsals", body: body)
    }

    static func updateRehearsal(id: String, title: String?, location: String?, scheduledAt: String?, notes: String?, setlistId: String?) async throws -> Rehearsal {
        var body: [String: Any] = [:]
        if let title { body["title"] = title }
        if let location { body["location"] = location }
        if let scheduledAt { body["scheduled_at"] = scheduledAt }
        if let notes { body["notes"] = notes }
        if let setlistId { body["setlist_id"] = setlistId }
        return try await APIClient.shared.put("/rehearsals/\(id)", body: body)
    }

    static func deleteRehearsal(id: String) async throws {
        try await APIClient.shared.delete("/rehearsals/\(id)")
    }

    /// Fetch a single rehearsal. Used by the deep-link router when the user
    /// taps a push notification and the home list hasn't been loaded yet.
    static func getRehearsal(id: String) async throws -> Rehearsal {
        try await APIClient.shared.get("/rehearsals/\(id)")
    }

    static func rsvp(rehearsalId: String, status: String) async throws -> RehearsalRSVP {
        try await APIClient.shared.post("/rehearsals/\(rehearsalId)/rsvp", body: ["status": status])
    }

    static func getMyRSVPs(bandId: String) async throws -> [RehearsalRSVP] {
        try await APIClient.shared.get("/rehearsals/my-rsvps?band_id=\(bandId)")
    }

    /// All members' RSVPs for a single rehearsal, with profile info for the roster UI.
    static func getRSVPs(rehearsalId: String) async throws -> [AttendanceRSVP] {
        try await APIClient.shared.get("/rehearsals/\(rehearsalId)/rsvps")
    }
}
