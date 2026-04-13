import SwiftUI

@MainActor
class SetlistViewModel: ObservableObject {
    @Published var setlists: [Setlist] = []
    @Published var setlistSongs: [SetlistSong] = []
    @Published var isLoading = false
    @Published var error: String?
    /// Map of `setlistId → status` for the current user's service RSVPs.
    @Published var rsvpStatuses: [String: String] = [:]

    private var bandId: String?

    func rsvpStatus(for setlistId: String) -> String? {
        rsvpStatuses[setlistId]
    }

    func loadSetlists(bandId: String) async {
        self.bandId = bandId
        isLoading = true
        do {
            async let setlistsTask = SetlistService.getSetlists(bandId: bandId)
            async let rsvpsTask    = SetlistService.getMyRSVPs(bandId: bandId)
            let (loadedSetlists, loadedRSVPs) = try await (setlistsTask, rsvpsTask)
            setlists = loadedSetlists
            var statuses: [String: String] = [:]
            for r in loadedRSVPs {
                if let sid = r.setlistId { statuses[sid] = r.status }
            }
            rsvpStatuses = statuses
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    /// Load just the current user's RSVPs across the band's services.
    /// Useful when the detail view is reached via deep-link / push without
    /// going through the list first.
    func loadMyRSVPs(bandId: String) async {
        do {
            let rsvps = try await SetlistService.getMyRSVPs(bandId: bandId)
            var statuses = rsvpStatuses
            for r in rsvps {
                if let sid = r.setlistId { statuses[sid] = r.status }
            }
            rsvpStatuses = statuses
        } catch {
            // Non-fatal — RSVP UI just won't pre-select anything.
        }
    }

    /// Set my RSVP for a service. Optimistically updates local state.
    func rsvp(setlistId: String, status: String) async {
        rsvpStatuses[setlistId] = status        // optimistic
        do {
            let response = try await SetlistService.rsvp(setlistId: setlistId, status: status)
            rsvpStatuses[setlistId] = response.status
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createSetlist(
        name: String,
        date: String?,
        time: String? = nil,
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
                time: time,
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
