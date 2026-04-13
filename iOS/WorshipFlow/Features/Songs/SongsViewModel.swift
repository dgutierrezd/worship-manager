import SwiftUI

@MainActor
class SongsViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var chordSheets: [ChordSheet] = []
    @Published var isLoading = false
    @Published var isBulkLoading = false
    @Published var error: String?

    var bandId: String?

    func loadSongs(bandId: String) async {
        self.bandId = bandId
        isLoading = true
        do {
            songs = try await SongService.getSongs(bandId: bandId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func addSong(
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
    ) async -> Bool {
        guard let bandId else { return false }
        do {
            let song = try await SongService.addSong(
                bandId: bandId, title: title, artist: artist, key: key,
                tempo: tempo, duration: duration, notes: notes,
                lyrics: lyrics, tags: tags, theme: theme,
                youtubeUrl: youtubeUrl, spotifyUrl: spotifyUrl
            )
            songs.append(song)
            songs.sort { $0.title < $1.title }
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func updateSong(
        _ song: Song,
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
    ) async -> Song? {
        guard let bandId else { return nil }
        // Only include non-nil values — JSONSerialization throws on Swift Optional-wrapped nils
        var body: [String: Any] = ["title": title]
        if let artist,    !artist.isEmpty    { body["artist"]       = artist }
        if let key,       !key.isEmpty       { body["default_key"]  = key }
        if let tempo                         { body["tempo_bpm"]    = tempo }
        if let duration                      { body["duration_sec"] = duration }
        if let notes,     !notes.isEmpty     { body["notes"]        = notes }
        if let lyrics,    !lyrics.isEmpty    { body["lyrics"]       = lyrics }
        if let tags,      !tags.isEmpty      { body["tags"]         = tags }
        if let theme,     !theme.isEmpty     { body["theme"]        = theme }
        if let youtubeUrl, !youtubeUrl.isEmpty { body["youtube_url"] = youtubeUrl }
        if let spotifyUrl, !spotifyUrl.isEmpty { body["spotify_url"] = spotifyUrl }
        do {
            let updated: Song = try await SongService.updateSong(bandId: bandId, songId: song.id, updates: body)
            if let idx = songs.firstIndex(where: { $0.id == song.id }) {
                songs[idx] = updated
            }
            return updated
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    func deleteSong(_ song: Song) async {
        guard let bandId else { return }
        do {
            try await SongService.deleteSong(bandId: bandId, songId: song.id)
            songs.removeAll { $0.id == song.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadChords(songId: String) async {
        do {
            chordSheets = try await SongService.getChords(songId: songId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Bulk Add

    /// Bulk-create many songs at once. Each entry is a (title, optional artist) pair.
    /// Returns the number of songs successfully added, or `nil` if the call failed.
    @discardableResult
    func bulkAddSongs(_ entries: [(title: String, artist: String?)]) async -> Int? {
        guard let bandId else { return nil }
        let payload = entries
            .map { (title: $0.title.trimmingCharacters(in: .whitespacesAndNewlines),
                    artist: $0.artist?.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !$0.title.isEmpty }
        guard !payload.isEmpty else { return 0 }

        isBulkLoading = true
        error = nil
        defer { isBulkLoading = false }

        do {
            let created = try await SongService.bulkAddSongs(bandId: bandId, songs: payload)
            songs.append(contentsOf: created)
            songs.sort { $0.title.lowercased() < $1.title.lowercased() }
            return created.count
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    // MARK: - Chord Sheets

    func saveChordSheet(songId: String, chordId: String?, instrument: String?, title: String?, content: String) async -> Bool {
        do {
            if let chordId {
                let updated = try await SongService.updateChordSheet(
                    chordId: chordId, content: content, title: title, instrument: instrument
                )
                if let idx = chordSheets.firstIndex(where: { $0.id == chordId }) {
                    chordSheets[idx] = updated
                }
            } else {
                let created = try await SongService.createChordSheet(
                    songId: songId, instrument: instrument, title: title, content: content
                )
                chordSheets.append(created)
            }
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }
}
