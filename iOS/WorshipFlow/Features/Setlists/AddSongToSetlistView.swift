import SwiftUI

// MARK: - Add Song to Setlist
//
// Lists existing band songs that aren't already in this setlist. If no song
// matches the user's search, an inline "Create song" affordance lets them
// add a brand-new song (title + artist) to the library AND drop it straight
// into the setlist in one tap — perfect when planning a service.

struct AddSongToSetlistView: View {
    let setlistId: String
    @ObservedObject var vm: SetlistViewModel
    @EnvironmentObject var bandVM: BandViewModel
    @Environment(\.dismiss) var dismiss

    @State private var songs: [Song] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var isCreating = false
    @State private var inlineArtist = ""
    @State private var error: String?

    var filteredSongs: [Song] {
        let existingSongIds = Set(vm.setlistSongs.compactMap { $0.songId })
        let available = songs.filter { !existingSongIds.contains($0.id) }
        if searchText.isEmpty { return available }
        return available.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.artist?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// True when the typed query doesn't match any existing song title exactly.
    private var canCreateInline: Bool {
        guard !trimmedSearch.isEmpty else { return false }
        return !songs.contains { $0.title.caseInsensitiveCompare(trimmedSearch) == .orderedSame }
    }

    var body: some View {
        NavigationStack {
            List {
                // Inline "Create new song" affordance — shows whenever the user
                // is searching and the query doesn't match an existing title.
                if canCreateInline {
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.appAccent)
                                Text("create_new_song".localized)
                                    .font(.appHeadline)
                                    .foregroundColor(.appPrimary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("title".localized)
                                    .font(.appSmall)
                                    .foregroundColor(.appSecondary)
                                Text(trimmedSearch)
                                    .font(.appBody)
                                    .foregroundColor(.appPrimary)
                            }

                            TextField("artist_optional".localized, text: $inlineArtist)
                                .appTextField()
                                .autocapitalization(.words)

                            Button {
                                Task { await createInlineAndAdd() }
                            } label: {
                                if isCreating {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 4)
                                } else {
                                    Label("create_and_add".localized, systemImage: "plus")
                                        .font(.appHeadline)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .primaryButton()
                            .disabled(isCreating)
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Color.appAccent.opacity(0.06))
                }

                // Existing songs
                if !filteredSongs.isEmpty {
                    Section(canCreateInline ? "your_library".localized : "") {
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
                }

                if let error {
                    Section {
                        Text(error)
                            .font(.appCaption)
                            .foregroundColor(.statusNo)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "search_songs".localized)
            .navigationTitle("add_song".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) { dismiss() }
                }
            }
            .task { await loadSongs() }
            .overlay {
                if isLoading && songs.isEmpty { ProgressView() }
            }
        }
    }

    // MARK: - Load

    private func loadSongs() async {
        guard let bandId = bandVM.currentBand?.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            songs = try await SongService.getSongs(bandId: bandId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Inline create + add

    private func createInlineAndAdd() async {
        guard let bandId = bandVM.currentBand?.id else { return }
        let title = trimmedSearch
        guard !title.isEmpty else { return }
        let artist = inlineArtist.trimmingCharacters(in: .whitespaces)

        isCreating = true
        defer { isCreating = false }
        error = nil

        do {
            // 1. Create song in the band's library
            let newSong = try await SongService.addSong(
                bandId: bandId,
                title: title,
                artist: artist.isEmpty ? nil : artist,
                key: nil, tempo: nil, duration: nil, notes: nil,
                lyrics: nil, tags: nil, theme: nil,
                youtubeUrl: nil, spotifyUrl: nil
            )
            // 2. Add it to the setlist
            let added = await vm.addSongToSetlist(
                setlistId: setlistId, songId: newSong.id, keyOverride: nil
            )
            if added { dismiss() }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
