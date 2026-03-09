import SwiftUI

struct EditSongView: View {
    let song: Song
    @ObservedObject var vm: SongsViewModel
    @Environment(\.dismiss) var dismiss
    var onSaved: ((Song) -> Void)?

    @State private var title: String
    @State private var artist: String
    @State private var selectedKey: String
    @State private var tempo: String
    @State private var durationMin: String
    @State private var durationSec: String
    @State private var notes: String
    @State private var youtubeUrl: String
    @State private var spotifyUrl: String
    @State private var isLoading = false

    private let keys = ["", "C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]

    init(song: Song, vm: SongsViewModel, onSaved: ((Song) -> Void)? = nil) {
        self.song = song
        self.vm = vm
        self.onSaved = onSaved
        _title = State(initialValue: song.title)
        _artist = State(initialValue: song.artist ?? "")
        _selectedKey = State(initialValue: song.defaultKey ?? "")
        _tempo = State(initialValue: song.tempoBpm.map { String($0) } ?? "")
        _notes = State(initialValue: song.notes ?? "")
        _youtubeUrl = State(initialValue: song.youtubeUrl ?? "")
        _spotifyUrl = State(initialValue: song.spotifyUrl ?? "")

        let totalSec = song.durationSec ?? 0
        _durationMin = State(initialValue: totalSec > 0 ? String(totalSec / 60) : "")
        _durationSec = State(initialValue: totalSec > 0 ? String(totalSec % 60) : "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TextField("song_title".localized, text: $title)
                        .appTextField()

                    TextField("artist".localized, text: $artist)
                        .appTextField()

                    // Key picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("default_key".localized)
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(keys, id: \.self) { key in
                                    Button {
                                        selectedKey = key
                                    } label: {
                                        Text(key.isEmpty ? "None" : key)
                                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                                            .foregroundColor(selectedKey == key ? .white : .appPrimary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(selectedKey == key ? Color.appPrimary : Color.appSurface)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.appDivider, lineWidth: selectedKey == key ? 0 : 1)
                                            )
                                    }
                                }
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("tempo".localized)
                                .font(.appCaption)
                                .foregroundColor(.appSecondary)
                            TextField("120", text: $tempo)
                                .appTextField()
                                .keyboardType(.numberPad)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("duration".localized)
                                .font(.appCaption)
                                .foregroundColor(.appSecondary)
                            HStack(spacing: 4) {
                                TextField("4", text: $durationMin)
                                    .appTextField()
                                    .keyboardType(.numberPad)
                                Text(":")
                                    .foregroundColor(.appSecondary)
                                TextField("30", text: $durationSec)
                                    .appTextField()
                                    .keyboardType(.numberPad)
                            }
                        }
                    }

                    TextField("youtube_link".localized, text: $youtubeUrl)
                        .appTextField()
                        .keyboardType(.URL)
                        .autocapitalization(.none)

                    TextField("spotify_link".localized, text: $spotifyUrl)
                        .appTextField()
                        .keyboardType(.URL)
                        .autocapitalization(.none)

                    TextField("Notes", text: $notes, axis: .vertical)
                        .appTextField()
                        .lineLimit(3...6)
                }
                .padding(24)
            }
            .background(Color.appBackground)
            .navigationTitle("Edit Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(title.isEmpty || isLoading)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() async {
        isLoading = true
        let tempoInt = Int(tempo)
        let totalSec: Int? = {
            let m = Int(durationMin) ?? 0
            let s = Int(durationSec) ?? 0
            return (m > 0 || s > 0) ? m * 60 + s : nil
        }()

        if let updated = await vm.updateSong(
            song,
            title: title,
            artist: artist.isEmpty ? nil : artist,
            key: selectedKey.isEmpty ? nil : selectedKey,
            tempo: tempoInt,
            duration: totalSec,
            notes: notes.isEmpty ? nil : notes,
            youtubeUrl: youtubeUrl.isEmpty ? nil : youtubeUrl,
            spotifyUrl: spotifyUrl.isEmpty ? nil : spotifyUrl
        ) {
            onSaved?(updated)
            dismiss()
        }
        isLoading = false
    }
}
