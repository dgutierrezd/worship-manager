import Foundation

enum SetlistService {
    static func getSetlists(bandId: String) async throws -> [Setlist] {
        try await APIClient.shared.get("/bands/\(bandId)/setlists")
    }

    static func createSetlist(
        bandId: String,
        name: String,
        date: String?,
        time: String? = nil,
        notes: String?,
        serviceType: String? = nil,
        location: String? = nil,
        theme: String? = nil
    ) async throws -> Setlist {
        var body: [String: Any] = ["name": name]
        if let date        { body["date"]         = date }
        if let time        { body["time"]         = time }
        if let notes       { body["notes"]        = notes }
        if let serviceType { body["service_type"] = serviceType }
        if let location    { body["location"]     = location }
        if let theme       { body["theme"]        = theme }
        return try await APIClient.shared.post("/bands/\(bandId)/setlists", body: body)
    }

    static func updateSetlist(
        id: String,
        name: String? = nil,
        date: String? = nil,
        time: String? = nil,
        notes: String? = nil,
        serviceType: String? = nil,
        location: String? = nil,
        theme: String? = nil
    ) async throws -> Setlist {
        var body: [String: Any] = [:]
        if let name        { body["name"]         = name }
        if let date        { body["date"]         = date }
        if let time        { body["time"]         = time }
        if let notes       { body["notes"]        = notes }
        if let serviceType { body["service_type"] = serviceType }
        if let location    { body["location"]     = location }
        if let theme       { body["theme"]        = theme }
        return try await APIClient.shared.put("/setlists/\(id)", body: body)
    }

    static func deleteSetlist(id: String) async throws {
        try await APIClient.shared.delete("/setlists/\(id)")
    }

    static func getSetlistSongs(setlistId: String) async throws -> [SetlistSong] {
        try await APIClient.shared.get("/setlists/\(setlistId)/songs")
    }

    static func addSongToSetlist(setlistId: String, songId: String, keyOverride: String?, notes: String?) async throws -> SetlistSong {
        var body: [String: Any] = ["song_id": songId]
        if let keyOverride { body["key_override"] = keyOverride }
        if let notes { body["notes"] = notes }
        return try await APIClient.shared.post("/setlists/\(setlistId)/songs", body: body)
    }

    static func removeSongFromSetlist(setlistId: String, songId: String) async throws {
        try await APIClient.shared.delete("/setlists/\(setlistId)/songs/\(songId)")
    }

    static func reorderSetlistSongs(setlistId: String, positions: [[String: Any]]) async throws {
        let _: MessageResponse = try await APIClient.shared.patch("/setlists/\(setlistId)/songs/reorder", body: ["positions": positions])
    }

    // MARK: - RSVPs

    /// Set the current user's RSVP for a service.
    static func rsvp(setlistId: String, status: String) async throws -> SetlistRSVP {
        try await APIClient.shared.post("/setlists/\(setlistId)/rsvp", body: ["status": status])
    }

    /// Current user's RSVPs across every service in a band (one row per service the user has responded to).
    static func getMyRSVPs(bandId: String) async throws -> [SetlistRSVP] {
        try await APIClient.shared.get("/setlists/my-rsvps?band_id=\(bandId)")
    }

    /// All members' RSVPs for a single service, with profile info for the roster UI.
    static func getRSVPs(setlistId: String) async throws -> [AttendanceRSVP] {
        try await APIClient.shared.get("/setlists/\(setlistId)/rsvps")
    }
}
