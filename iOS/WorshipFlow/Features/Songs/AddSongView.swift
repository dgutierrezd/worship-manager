import SwiftUI

struct AddSongView: View {
    @ObservedObject var vm: SongsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var artist = ""
    @State private var selectedKey = ""
    @State private var tempo = ""
    @State private var durationMin = ""
    @State private var durationSec = ""
    @State private var notes = ""
    @State private var youtubeUrl = ""
    @State private var spotifyUrl = ""
    @State private var isLoading = false

    private let keys = ["", "C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]

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
            .navigationTitle("new_song".localized)
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

        let success = await vm.addSong(
            title: title,
            artist: artist.isEmpty ? nil : artist,
            key: selectedKey.isEmpty ? nil : selectedKey,
            tempo: tempoInt,
            duration: totalSec,
            notes: notes.isEmpty ? nil : notes,
            youtubeUrl: youtubeUrl.isEmpty ? nil : youtubeUrl,
            spotifyUrl: spotifyUrl.isEmpty ? nil : spotifyUrl
        )

        isLoading = false
        if success { dismiss() }
    }
}
