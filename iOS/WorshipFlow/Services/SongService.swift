import Foundation

enum SongService {
    static func getSongs(bandId: String) async throws -> [Song] {
        try await APIClient.shared.get("/bands/\(bandId)/songs")
    }

    static func addSong(bandId: String, title: String, artist: String?, key: String?, tempo: Int?, duration: Int?, notes: String?, youtubeUrl: String?, spotifyUrl: String?) async throws -> Song {
        var body: [String: Any] = ["title": title]
        if let artist, !artist.isEmpty { body["artist"] = artist }
        if let key, !key.isEmpty { body["default_key"] = key }
        if let tempo { body["tempo_bpm"] = tempo }
        if let duration { body["duration_sec"] = duration }
        if let notes, !notes.isEmpty { body["notes"] = notes }
        if let youtubeUrl, !youtubeUrl.isEmpty { body["youtube_url"] = youtubeUrl }
        if let spotifyUrl, !spotifyUrl.isEmpty { body["spotify_url"] = spotifyUrl }
        return try await APIClient.shared.post("/bands/\(bandId)/songs", body: body)
    }

    static func updateSong(bandId: String, songId: String, updates: [String: Any]) async throws -> Song {
        try await APIClient.shared.put("/bands/\(bandId)/songs/\(songId)", body: updates)
    }

    static func deleteSong(bandId: String, songId: String) async throws {
        try await APIClient.shared.delete("/bands/\(bandId)/songs/\(songId)")
    }

    // Chord Sheets
    static func getChords(songId: String) async throws -> [ChordSheet] {
        try await APIClient.shared.get("/songs/\(songId)/chords")
    }

    static func createChordSheet(songId: String, instrument: String?, title: String?, content: String) async throws -> ChordSheet {
        var body: [String: Any] = ["content": content]
        if let instrument { body["instrument"] = instrument }
        if let title { body["title"] = title }
        return try await APIClient.shared.post("/songs/\(songId)/chords", body: body)
    }

    static func updateChordSheet(chordId: String, content: String?, title: String?, instrument: String?) async throws -> ChordSheet {
        var body: [String: Any] = [:]
        if let content { body["content"] = content }
        if let title { body["title"] = title }
        if let instrument { body["instrument"] = instrument }
        return try await APIClient.shared.put("/chords/\(chordId)", body: body)
    }
}
