import SwiftUI

struct SongLibraryView: View {
    @EnvironmentObject var bandVM: BandViewModel
    @StateObject private var vm = SongsViewModel()
    @State private var searchText = ""
    @State private var showAddSong = false

    var filteredSongs: [Song] {
        if searchText.isEmpty { return vm.songs }
        return vm.songs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.artist?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if vm.songs.isEmpty && !vm.isLoading {
                    EmptyStateView(
                        icon: "🎵",
                        title: "No songs yet",
                        subtitle: "Add your first song to get started",
                        buttonTitle: "new_song".localized
                    ) {
                        showAddSong = true
                    }
                } else {
                    List {
                        ForEach(filteredSongs) { song in
                            NavigationLink {
                                SongDetailView(song: song)
                                    .environmentObject(vm)
                            } label: {
                                SongRow(song: song)
                            }
                        }
                        .onDelete { indexSet in
                            Task {
                                for idx in indexSet {
                                    await vm.deleteSong(filteredSongs[idx])
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search songs")
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("songs".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSong = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSong) {
                AddSongView(vm: vm)
            }
            .refreshable {
                guard let bandId = bandVM.currentBand?.id else { return }
                await vm.loadSongs(bandId: bandId)
            }
            .task {
                guard let bandId = bandVM.currentBand?.id else { return }
                await vm.loadSongs(bandId: bandId)
            }
        }
        .background(Color.appBackground)
    }
}

struct SongRow: View {
    let song: Song

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.appHeadline)
                    .foregroundColor(.appPrimary)

                HStack(spacing: 8) {
                    if let artist = song.artist {
                        Text(artist)
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)
                    }
                    if let duration = song.formattedDuration {
                        Text(duration)
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)
                    }
                }
            }

            Spacer()

            if let key = song.defaultKey {
                KeyBadge(key: key)
            }
        }
        .padding(.vertical, 4)
    }
}
