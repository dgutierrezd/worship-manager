import Foundation
import SwiftUI

@MainActor
final class MultitracksViewModel: ObservableObject {

    @Published var stems: [SongStem] = []
    @Published var isLoadingList = false
    @Published var error: String?

    let player = MultitrackPlayerEngine()
    let songId: String

    init(songId: String) {
        self.songId = songId
    }

    // MARK: - Load stem list

    func loadStems() async {
        isLoadingList = true
        error = nil
        defer { isLoadingList = false }
        do {
            let fetched = try await SongService.fetchStems(songId: songId)
            self.stems = fetched
            // Load audio graph whenever the stem list changes (cheap if cached)
            await player.load(songId: songId, stems: fetched)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Add / update / delete

    func addStem(kind: String, label: String, url: String) async -> Bool {
        error = nil
        do {
            let stem = try await SongService.addStem(
                songId: songId,
                kind: kind,
                label: label,
                url: url,
                position: stems.count
            )
            stems.append(stem)
            await player.load(songId: songId, stems: stems)
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func updateStem(_ stem: SongStem, label: String?, kind: String?, url: String?) async -> Bool {
        error = nil
        do {
            let updated = try await SongService.updateStem(
                songId: songId,
                stemId: stem.id,
                label: label,
                kind: kind,
                url: url
            )
            if let idx = stems.firstIndex(where: { $0.id == stem.id }) {
                stems[idx] = updated
            }
            // If URL changed, we need to purge the old cache and reload the graph
            if url != nil, url != stem.url {
                MultitrackPlayerEngine.purgeCache(songId: songId, stemId: stem.id)
                await player.load(songId: songId, stems: stems)
            }
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func deleteStem(_ stem: SongStem) async {
        error = nil
        do {
            try await SongService.deleteStem(songId: songId, stemId: stem.id)
            stems.removeAll(where: { $0.id == stem.id })
            MultitrackPlayerEngine.purgeCache(songId: songId, stemId: stem.id)
            await player.load(songId: songId, stems: stems)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
