import SwiftUI

@MainActor
class SetlistViewModel: ObservableObject {
    @Published var setlists: [Setlist] = []
    @Published var setlistSongs: [SetlistSong] = []
    @Published var isLoading = false
    @Published var error: String?

    private var bandId: String?

    func loadSetlists(bandId: String) async {
        self.bandId = bandId
        isLoading = true
        do {
            setlists = try await SetlistService.getSetlists(bandId: bandId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func createSetlist(
        name: String,
        date: String?,
        notes: String?,
        serviceType: String? = nil,
        location: String? = nil,
        theme: String? = nil
    ) async -> Setlist? {
        guard let bandId else { return nil }
        do {
            let setlist = try await SetlistService.createSetlist(
                bandId: bandId,
                name: name,
                date: date,
                notes: notes,
                serviceType: serviceType,
                location: location,
                theme: theme
            )
            setlists.insert(setlist, at: 0)
            return setlist
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    func deleteSetlist(_ setlist: Setlist) async {
        do {
            try await SetlistService.deleteSetlist(id: setlist.id)
            setlists.removeAll { $0.id == setlist.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadSetlistSongs(setlistId: String) async {
        do {
            setlistSongs = try await SetlistService.getSetlistSongs(setlistId: setlistId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func addSongToSetlist(setlistId: String, songId: String, keyOverride: String?) async -> Bool {
        do {
            let item = try await SetlistService.addSongToSetlist(
                setlistId: setlistId, songId: songId, keyOverride: keyOverride, notes: nil
            )
            setlistSongs.append(item)
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func removeSongFromSetlist(setlistId: String, songId: String) async {
        do {
            try await SetlistService.removeSongFromSetlist(setlistId: setlistId, songId: songId)
            setlistSongs.removeAll { $0.songId == songId }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func moveSetlistSong(setlistId: String, from source: IndexSet, to destination: Int) {
        setlistSongs.move(fromOffsets: source, toOffset: destination)
        // Update positions
        let positions = setlistSongs.enumerated().map { idx, item in
            ["id": item.id, "position": idx + 1] as [String: Any]
        }
        Task {
            try? await SetlistService.reorderSetlistSongs(setlistId: setlistId, positions: positions)
        }
    }
}
