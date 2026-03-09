import SwiftUI

struct SongDetailView: View {
    @State private var song: Song
    @EnvironmentObject var bandVM: BandViewModel
    @StateObject private var vm = SongsViewModel()
    @State private var selectedTab = 0
    @State private var showChordsEditor = false
    @State private var showEditSong = false
    @State private var selectedChordSheet: ChordSheet?
    @State private var instrumentFilter = "All"

    private let instrumentFilters = ["All", "Guitar", "Piano", "Bass", "Drums"]

    init(song: Song) {
        _song = State(initialValue: song)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text(song.title)
                        .font(.appLargeTitle)
                        .foregroundColor(.appPrimary)

                    HStack(spacing: 12) {
                        if let artist = song.artist {
                            Text(artist)
                                .font(.appBody)
                                .foregroundColor(.appSecondary)
                        }
                        if let key = song.defaultKey {
                            KeyBadge(key: key)
                        }
                        if let bpm = song.tempoBpm {
                            Text("\(bpm) BPM")
                                .font(.appCaption)
                                .foregroundColor(.appSecondary)
                        }
                        if let dur = song.formattedDuration {
                            Text(dur)
                                .font(.appCaption)
                                .foregroundColor(.appSecondary)
                        }
                    }
                }
                .padding(.vertical, 24)

                // Tab Picker
                Picker("", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("chords".localized).tag(1)
                    Text("Notes").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Tab Content
                switch selectedTab {
                case 0: overviewTab
                case 1: chordsTab
                case 2: notesTab
                default: EmptyView()
                }
            }
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        PracticeManager.shared.startSession(songs: [
                            SetlistSong(
                                id: song.id,
                                songId: song.id,
                                position: 1,
                                keyOverride: nil,
                                notes: nil,
                                songs: song
                            )
                        ])
                    } label: {
                        Image(systemName: "metronome")
                            .foregroundColor(.appAccent)
                    }

                    Button {
                        showEditSong = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundColor(.appAccent)
                    }
                }
            }
        }
        .task {
            vm.bandId = bandVM.currentBand?.id
            await vm.loadChords(songId: song.id)
        }
        .sheet(isPresented: $showChordsEditor) {
            ChordsEditorView(
                songId: song.id,
                chordSheet: selectedChordSheet,
                vm: vm
            )
        }
        .sheet(isPresented: $showEditSong) {
            EditSongView(song: song, vm: vm) { updated in
                song = updated
            }
        }
    }

    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let key = song.defaultKey {
                DetailRow(label: "default_key".localized, value: key)
            }
            if let bpm = song.tempoBpm {
                DetailRow(label: "tempo".localized, value: "\(bpm) BPM")
            }
            if let dur = song.formattedDuration {
                DetailRow(label: "duration".localized, value: dur)
            }
            if let youtube = song.youtubeUrl, !youtube.isEmpty {
                DetailRow(label: "youtube_link".localized, value: youtube, isLink: true)
            }
            if let spotify = song.spotifyUrl, !spotify.isEmpty {
                DetailRow(label: "spotify_link".localized, value: spotify, isLink: true)
            }
            if let notes = song.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)
                    Text(notes)
                        .font(.appBody)
                        .foregroundColor(.appPrimary)
                }
            }
        }
        .padding(24)
    }

    private var chordsTab: some View {
        VStack(spacing: 16) {
            // Instrument filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(instrumentFilters, id: \.self) { filter in
                        Button {
                            instrumentFilter = filter
                        } label: {
                            Text(filter)
                                .font(.appCaption)
                                .foregroundColor(instrumentFilter == filter ? .white : .appPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(instrumentFilter == filter ? Color.appPrimary : Color.appSurface)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(Color.appDivider, lineWidth: instrumentFilter == filter ? 0 : 1)
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }

            let filtered = vm.chordSheets.filter { sheet in
                instrumentFilter == "All" || sheet.instrument == instrumentFilter
            }

            if filtered.isEmpty {
                VStack(spacing: 12) {
                    Text("no_chords_yet".localized)
                        .font(.appBody)
                        .foregroundColor(.appSecondary)
                        .multilineTextAlignment(.center)

                    Button {
                        selectedChordSheet = nil
                        showChordsEditor = true
                    } label: {
                        Text("edit_chords".localized)
                            .font(.appHeadline)
                            .foregroundColor(.appAccent)
                    }
                }
                .padding(32)
            } else {
                ForEach(filtered) { sheet in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(sheet.title)
                                .font(.appHeadline)
                                .foregroundColor(.appPrimary)

                            if let instrument = sheet.instrument {
                                Text(instrument)
                                    .font(.appCaption)
                                    .foregroundColor(.appSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.appDivider)
                                    .clipShape(Capsule())
                            }

                            Spacer()

                            Button {
                                selectedChordSheet = sheet
                                showChordsEditor = true
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundColor(.appAccent)
                            }
                        }

                        // Chord progression display (degree-based)
                        if let progression = ChordProgression.from(json: sheet.content) {
                            chordProgressionView(progression)
                        } else {
                            // Fallback for old plain-text chord sheets
                            Text(sheet.content)
                                .font(.appMono)
                                .foregroundColor(.appPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(16)
                    .cardStyle()
                    .padding(.horizontal)
                }
            }

            // Add chord sheet button
            Button {
                selectedChordSheet = nil
                showChordsEditor = true
            } label: {
                Label("edit_chords".localized, systemImage: "plus")
                    .font(.appHeadline)
                    .foregroundColor(.appAccent)
            }
            .padding()
        }
        .padding(.top, 16)
    }

    // MARK: - Chord Progression Display

    private func chordProgressionView(_ progression: ChordProgression) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(progression.sections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    Text(section.name.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.appAccent)
                        .tracking(1.2)

                    FlowLayout(spacing: 6) {
                        ForEach(section.chords) { chord in
                            VStack(spacing: 1) {
                                Text("\(chord.degree)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                Text(chord.isPass ? "pass" : "full")
                                    .font(.system(size: 8, weight: .medium))
                                    .textCase(.uppercase)
                            }
                            .foregroundColor(chord.isPass ? .appSecondary : .white)
                            .frame(width: 42, height: 46)
                            .background(chord.isPass ? Color.appBackground : Color.appPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(chord.isPass ? Color.appDivider : Color.clear, lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
    }

    private var notesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let notes = song.notes, !notes.isEmpty {
                Text(notes)
                    .font(.appBody)
                    .foregroundColor(.appPrimary)
            } else {
                Text("No notes yet")
                    .font(.appBody)
                    .foregroundColor(.appSecondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var isLink: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.appCaption)
                .foregroundColor(.appSecondary)
                .frame(width: 100, alignment: .leading)

            if isLink, let url = URL(string: value) {
                Link(destination: url) {
                    Text(value)
                        .font(.appBody)
                        .foregroundColor(.appAccent)
                        .lineLimit(1)
                }
            } else {
                Text(value)
                    .font(.appBody)
                    .foregroundColor(.appPrimary)
            }
        }
    }
}
