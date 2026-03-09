import SwiftUI

struct AddSongToSetlistView: View {
    let setlistId: String
    @ObservedObject var vm: SetlistViewModel
    @EnvironmentObject var bandVM: BandViewModel
    @Environment(\.dismiss) var dismiss

    @State private var songs: [Song] = []
    @State private var searchText = ""
    @State private var isLoading = false

    var filteredSongs: [Song] {
        let existingSongIds = Set(vm.setlistSongs.compactMap { $0.songId })
        let available = songs.filter { !existingSongIds.contains($0.id) }
        if searchText.isEmpty { return available }
        return available.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.artist?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredSongs) { song in
                    Button {
                        Task {
                            let success = await vm.addSongToSetlist(
                                setlistId: setlistId, songId: song.id, keyOverride: nil
                            )
                            if success { dismiss() }
                        }
                    } label: {
                        SongRow(song: song)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search songs")
            .navigationTitle("add_song".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                guard let bandId = bandVM.currentBand?.id else { return }
                isLoading = true
                do {
                    songs = try await SongService.getSongs(bandId: bandId)
                } catch {
                    print("Failed to load songs: \(error)")
                }
                isLoading = false
            }
            .overlay {
                if isLoading { ProgressView() }
            }
        }
    }
}
