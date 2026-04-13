import Foundation

enum SongService {
    static func getSongs(bandId: String) async throws -> [Song] {
        try await APIClient.shared.get("/bands/\(bandId)/songs")
    }

    static func addSong(
        bandId: String,
        title: String,
        artist: String?,
        key: String?,
        tempo: Int?,
        duration: Int?,
        notes: String?,
        lyrics: String? = nil,
        tags: [String]? = nil,
        theme: String? = nil,
        youtubeUrl: String?,
        spotifyUrl: String?
    ) async throws -> Song {
        var body: [String: Any] = ["title": title]
        if let artist, !artist.isEmpty    { body["artist"]       = artist }
        if let key, !key.isEmpty          { body["default_key"]  = key }
        if let tempo                      { body["tempo_bpm"]    = tempo }
        if let duration                   { body["duration_sec"] = duration }
        if let notes, !notes.isEmpty      { body["notes"]        = notes }
        if let lyrics, !lyrics.isEmpty    { body["lyrics"]       = lyrics }
        if let tags, !tags.isEmpty        { body["tags"]         = tags }
        if let theme, !theme.isEmpty      { body["theme"]        = theme }
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

    // MARK: - Multitracks (Stems)

    static func fetchStems(songId: String) async throws -> [SongStem] {
        try await APIClient.shared.get("/songs/\(songId)/stems")
    }

    static func addStem(
        songId: String,
        kind: String,
        label: String,
        url: String,
        position: Int? = nil
    ) async throws -> SongStem {
        var body: [String: Any] = [
            "kind": kind,
            "label": label,
            "url": url,
        ]
        if let position { body["position"] = position }
        return try await APIClient.shared.post("/songs/\(songId)/stems", body: body)
    }

    static func updateStem(
        songId: String,
        stemId: String,
        label: String? = nil,
        kind: String? = nil,
        url: String? = nil,
        position: Int? = nil
    ) async throws -> SongStem {
        var body: [String: Any] = [:]
        if let label    { body["label"]    = label }
        if let kind     { body["kind"]     = kind }
        if let url      { body["url"]      = url }
        if let position { body["position"] = position }
        return try await APIClient.shared.patch("/songs/\(songId)/stems/\(stemId)", body: body)
    }

    static func deleteStem(songId: String, stemId: String) async throws {
        try await APIClient.shared.delete("/songs/\(songId)/stems/\(stemId)")
    }

    // MARK: - Bulk add

    /// Inserts many songs in a single request. Each entry is `(title, optional artist)`.
    /// Returns the created `Song` records in insertion order.
    static func bulkAddSongs(
        bandId: String,
        songs: [(title: String, artist: String?)]
    ) async throws -> [Song] {
        let payload: [[String: Any]] = songs.map { entry in
            var row: [String: Any] = ["title": entry.title]
            if let artist = entry.artist, !artist.isEmpty { row["artist"] = artist }
            return row
        }
        struct Response: Decodable { let songs: [Song] }
        let response: Response = try await APIClient.shared.post(
            "/bands/\(bandId)/songs/bulk",
            body: ["songs": payload]
        )
        return response.songs
    }
}
