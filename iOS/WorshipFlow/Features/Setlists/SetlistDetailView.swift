import SwiftUI

struct SetlistDetailView: View {
    let setlist: Setlist
    @EnvironmentObject var bandVM: BandViewModel
    @StateObject private var vm = SetlistViewModel()
    @State private var showAddSong = false

    // Any band member can edit setlists — no role-based gating.
    var canEdit: Bool { bandVM.currentBand != nil }

    var body: some View {
        List {
            // Header section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    if let date = setlist.formattedDate {
                        Label(date, systemImage: "calendar")
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)
                    }

                    Text("\(vm.setlistSongs.count) songs")
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)

                    if let notes = setlist.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.appBody)
                            .foregroundColor(.appSecondary)
                    }
                }
            }

            // Songs
            Section {
                ForEach(vm.setlistSongs) { item in
                    HStack {
                        Text("\(item.position)")
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.songs?.title ?? "Unknown")
                                .font(.appHeadline)
                                .foregroundColor(.appPrimary)

                            HStack(spacing: 8) {
                                if let key = item.displayKey {
                                    KeyBadge(key: key)
                                }
                                if let dur = item.songs?.formattedDuration {
                                    Text(dur)
                                        .font(.appCaption)
                                        .foregroundColor(.appSecondary)
                                }
                                if let artist = item.songs?.artist {
                                    Text(artist)
                                        .font(.appCaption)
                                        .foregroundColor(.appSecondary)
                                }
                            }
                        }

                        Spacer()

                        if let song = item.songs {
                            NavigationLink {
                                SongDetailView(song: song)
                            } label: {
                                Text("my_chords".localized)
                                    .font(.appCaption)
                                    .foregroundColor(.appAccent)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onMove { source, destination in
                    vm.moveSetlistSong(setlistId: setlist.id, from: source, to: destination)
                }
                .onDelete { indexSet in
                    Task {
                        for idx in indexSet {
                            let item = vm.setlistSongs[idx]
                            if let songId = item.songId {
                                await vm.removeSongFromSetlist(setlistId: setlist.id, songId: songId)
                            }
                        }
                    }
                }
            }

            // Practice session
            if !vm.setlistSongs.isEmpty {
                Section {
                    Button {
                        PracticeManager.shared.startSession(songs: vm.setlistSongs)
                    } label: {
                        Label("practice_session".localized, systemImage: "metronome")
                            .foregroundColor(.appAccent)
                    }
                }
            }

            // Add song
            if canEdit {
                Section {
                    Button {
                        showAddSong = true
                    } label: {
                        Label("add_song".localized, systemImage: "plus")
                            .foregroundColor(.appAccent)
                    }
                }
            }
        }
        .navigationTitle(setlist.name)
        .toolbar {
            if canEdit {
                EditButton()
            }
        }
        .sheet(isPresented: $showAddSong) {
            AddSongToSetlistView(setlistId: setlist.id, vm: vm)
        }
        .task {
            await vm.loadSetlistSongs(setlistId: setlist.id)
        }
    }
}
