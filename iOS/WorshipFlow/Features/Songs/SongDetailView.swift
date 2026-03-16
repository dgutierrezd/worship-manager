import SwiftUI

// MARK: - Song Detail View (OnStage-inspired)

struct SongDetailView: View {
    @State private var song: Song
    @EnvironmentObject var bandVM: BandViewModel
    @StateObject private var vm = SongsViewModel()

    @State private var selectedTab = 0
    @State private var transposeSteps = 0
    @State private var chordEditorTarget: ChordEditorTarget? // nil = closed; value = edit or new
    @State private var showEditSong = false
    @State private var showPresenter = false
    @State private var instrumentFilter = "All"

    private let instrumentFilters = ["All", "Guitar", "Piano", "Bass", "Drums", "Keys", "Strings"]

    init(song: Song) {
        _song = State(initialValue: song)
    }

    var transposedKey: String? {
        guard let key = song.defaultKey else { return nil }
        return transposeSteps == 0 ? key : Song.transpose(key: key, steps: transposeSteps)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                songHeader
                    .padding(.bottom, 8)

                // Transpose control (visible when a key is set)
                if song.defaultKey != nil {
                    transposeControl
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }

                // Tab picker
                Picker("", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Chords").tag(1)
                    Text("Lyrics").tag(2)
                    Text("Notes").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

                Group {
                    switch selectedTab {
                    case 0: overviewTab
                    case 1: chordsTab
                    case 2: lyricsTab
                    case 3: notesTab
                    default: EmptyView()
                    }
                }
            }
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 14) {
                    // Presenter mode
                    Button {
                        showPresenter = true
                    } label: {
                        Image(systemName: "play.display")
                            .foregroundColor(.appAccent)
                    }

                    // Metronome / Practice
                    Button {
                        PracticeManager.shared.startSession(songs: [
                            SetlistSong(id: song.id, songId: song.id, position: 1,
                                        keyOverride: transposedKey != song.defaultKey ? transposedKey : nil,
                                        notes: nil, songs: song)
                        ])
                    } label: {
                        Image(systemName: "metronome")
                            .foregroundColor(.appAccent)
                    }

                    // Edit
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
        // .sheet(item:) guarantees the correct ChordSheet is always bound when the editor opens
        .sheet(item: $chordEditorTarget) { target in
            ChordsEditorView(
                songId: song.id,
                songKey: song.defaultKey,
                chordSheet: target.sheet,
                vm: vm
            )
        }
        .sheet(isPresented: $showEditSong) {
            EditSongView(song: song, vm: vm) { updated in
                song = updated
            }
        }
        .fullScreenCover(isPresented: $showPresenter) {
            SongPresenterView(song: song, transposedKey: transposedKey)
        }
    }

    // MARK: - Header

    private var songHeader: some View {
        VStack(spacing: 10) {
            Text(song.title)
                .font(.appLargeTitle)
                .foregroundColor(.appPrimary)
                .multilineTextAlignment(.center)

            if let artist = song.artist {
                Text(artist)
                    .font(.appBody)
                    .foregroundColor(.appSecondary)
            }

            HStack(spacing: 12) {
                if let key = transposedKey {
                    KeyBadge(key: key)
                }
                if let bpm = song.tempoBpm {
                    Label("\(bpm) BPM", systemImage: "metronome")
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)
                }
                if let dur = song.formattedDuration {
                    Label(dur, systemImage: "clock")
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)
                }
            }

            // Tags
            if let tags = song.tags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.appAccent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.appAccent.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.top, 24)
        .padding(.horizontal, 16)
    }

    // MARK: - Transpose Control

    private var transposeControl: some View {
        HStack(spacing: 0) {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 13))
                .foregroundColor(.appSecondary)
                .padding(.trailing, 8)

            Text("Transpose")
                .font(.appCaption)
                .foregroundColor(.appSecondary)

            Spacer()

            HStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        transposeSteps -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appPrimary)
                        .frame(width: 36, height: 32)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Text(transposeSteps == 0 ? "Original" : (transposeSteps > 0 ? "+\(transposeSteps)" : "\(transposeSteps)"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(transposeSteps == 0 ? .appSecondary : .appAccent)
                    .frame(minWidth: 64)
                    .multilineTextAlignment(.center)

                Button {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        transposeSteps += 1
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appPrimary)
                        .frame(width: 36, height: 32)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.appDivider, lineWidth: 1)
            )

            if transposeSteps != 0 {
                Button {
                    withAnimation { transposeSteps = 0 }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13))
                        .foregroundColor(.appSecondary)
                }
                .padding(.leading, 10)
            }
        }
        .padding(12)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appDivider, lineWidth: 1))
    }

    // MARK: - Overview Tab

    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let key = transposedKey {
                detailRow(label: "Key",
                          value: transposeSteps == 0 ? key : "\(key) (transposed \(transposeSteps > 0 ? "+" : "")\(transposeSteps))")
            }
            if let bpm = song.tempoBpm   { detailRow(label: "Tempo",    value: "\(bpm) BPM") }
            if let dur = song.formattedDuration { detailRow(label: "Duration", value: dur) }
            if let theme = song.theme, !theme.isEmpty { detailRow(label: "Theme", value: theme) }

            if let youtube = song.youtubeUrl, !youtube.isEmpty {
                linkRow(label: "YouTube", url: youtube)
            }
            if let spotify = song.spotifyUrl, !spotify.isEmpty {
                linkRow(label: "Spotify", url: spotify)
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.appCaption)
                .foregroundColor(.appSecondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.appBody)
                .foregroundColor(.appPrimary)
            Spacer()
        }
        .padding(.vertical, 10)
        .overlay(Divider(), alignment: .bottom)
    }

    private func linkRow(label: String, url: String) -> some View {
        HStack {
            Text(label)
                .font(.appCaption)
                .foregroundColor(.appSecondary)
                .frame(width: 90, alignment: .leading)
            if let u = URL(string: url) {
                Link(url, destination: u)
                    .font(.appCaption)
                    .foregroundColor(.appAccent)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 10)
        .overlay(Divider(), alignment: .bottom)
    }

    // MARK: - Chords Tab

    private var chordsTab: some View {
        VStack(spacing: 16) {
            // Instrument filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(instrumentFilters, id: \.self) { filter in
                        Button { instrumentFilter = filter } label: {
                            Text(filter)
                                .font(.appCaption)
                                .foregroundColor(instrumentFilter == filter ? .white : .appPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(instrumentFilter == filter ? Color.appPrimary : Color.appSurface)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.appDivider,
                                                         lineWidth: instrumentFilter == filter ? 0 : 1))
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            let filtered = vm.chordSheets.filter {
                instrumentFilter == "All" || $0.instrument == instrumentFilter
            }

            if filtered.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "guitars")
                        .font(.system(size: 40))
                        .foregroundColor(.appDivider)
                    Text("No chord sheets yet")
                        .font(.appBody)
                        .foregroundColor(.appSecondary)
                    Button {
                        chordEditorTarget = ChordEditorTarget(sheet: nil)
                    } label: {
                        Label("Create Chord Sheet", systemImage: "plus.circle.fill")
                            .font(.appCaption)
                            .foregroundColor(.appAccent)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(48)
            } else {
                ForEach(filtered) { sheet in
                    VStack(alignment: .leading, spacing: 14) {
                        // Sheet header
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(sheet.title)
                                    .font(.appHeadline)
                                    .foregroundColor(.appPrimary)
                                if let instrument = sheet.instrument {
                                    Text(instrument)
                                        .font(.appCaption)
                                        .foregroundColor(.appSecondary)
                                }
                            }
                            Spacer()
                            Button {
                                // .sheet(item:) guarantees chordEditorTarget is set before view builds
                                chordEditorTarget = ChordEditorTarget(sheet: sheet)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "pencil")
                                    Text("Edit")
                                        .font(.appCaption)
                                }
                                .foregroundColor(.appAccent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.appAccent.opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }

                        if let progression = ChordProgression.from(json: sheet.content) {
                            chordProgressionView(progression)
                        } else {
                            Text(sheet.content)
                                .font(.appMono)
                                .foregroundColor(.appPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(16)
                    .cardStyle()
                    .padding(.horizontal, 16)
                }

                Button {
                    chordEditorTarget = ChordEditorTarget(sheet: nil)
                } label: {
                    Label("Add Another Sheet", systemImage: "plus")
                        .font(.appCaption)
                        .foregroundColor(.appAccent)
                }
                .padding(.bottom, 16)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Chord Progression Viewer

    private func chordProgressionView(_ progression: ChordProgression) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Key + legend header
            HStack(spacing: 0) {
                if let key = transposedKey {
                    HStack(spacing: 6) {
                        Image(systemName: "music.note")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.appAccent)
                        Text("Key of \(key)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.appPrimary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.appAccent.opacity(0.1))
                    .clipShape(Capsule())
                    .padding(.trailing, 12)
                }

                HStack(spacing: 12) {
                    legendPill(color: chordFnColor(.tonic),       label: "Tonic")
                    legendPill(color: chordFnColor(.subdominant), label: "Sub-dom")
                    legendPill(color: chordFnColor(.dominant),    label: "Dominant")
                }
                Spacer()
            }

            ForEach(progression.sections) { section in
                VStack(alignment: .leading, spacing: 10) {
                    // Section label
                    HStack(spacing: 6) {
                        Rectangle()
                            .fill(Color.appAccent)
                            .frame(width: 3, height: 14)
                            .clipShape(Capsule())
                        Text(section.name.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.appAccent)
                            .tracking(1.6)
                    }

                    // Measures: beat-slot based (pass chords are half-beats)
                    let slots = buildBeatSlots(from: section.chords)
                    let bars = stride(from: 0, to: slots.count, by: 4).map {
                        Array(slots[$0..<min($0 + 4, slots.count)])
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(bars.indices, id: \.self) { barIdx in
                            HStack(spacing: 6) {
                                // Bar number
                                Text("\(barIdx + 1)")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.appSecondary)
                                    .frame(width: 16)

                                // Beat slots
                                HStack(spacing: 6) {
                                    ForEach(bars[barIdx].indices, id: \.self) { slotIdx in
                                        viewerBeatSlotView(bars[barIdx][slotIdx])
                                    }
                                    // Empty beat placeholders
                                    ForEach(bars[barIdx].count..<4, id: \.self) { _ in
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.appBackground)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 88)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.appDivider.opacity(0.4),
                                                            style: StrokeStyle(lineWidth: 1, dash: [4]))
                                            )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /// Chord tile in the read-only viewer — Roman numeral as hero, chord name as supporting detail
    private func viewerChordTile(_ chord: ChordEntry) -> some View {
        let fnColor = chordFnColor(chord.harmonicFunction)
        let isPass  = chord.isPass
        let name    = chord.chordName(inKey: transposedKey)
        let bgOpacity: Double = isPass ? 0.06 : 0.14
        let textOpacity: Double = isPass ? 0.4 : 1.0

        return VStack(spacing: 2) {
            // Roman numeral — hero element
            Text(chord.romanNumeral)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(fnColor.opacity(textOpacity))

            // Chord name — supporting detail
            Text(name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(isPass ? .appSecondary.opacity(0.6) : .appPrimary.opacity(0.75))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 88)
        .background(fnColor.opacity(bgOpacity))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(fnColor.opacity(isPass ? 0.2 : 0.4), lineWidth: 1.5)
        )
        .shadow(color: isPass ? .clear : fnColor.opacity(0.08), radius: 3, x: 0, y: 1)
    }

    // MARK: - Beat Slot Helpers

    /// Groups consecutive pass chords into pairs so they share one beat slot.
    private func buildBeatSlots(from chords: [ChordEntry]) -> [[ChordEntry]] {
        var slots: [[ChordEntry]] = []
        var i = 0
        while i < chords.count {
            if chords[i].isPass {
                var slot = [chords[i]]
                if i + 1 < chords.count && chords[i + 1].isPass {
                    slot.append(chords[i + 1])
                    i += 2
                } else {
                    i += 1
                }
                slots.append(slot)
            } else {
                slots.append([chords[i]])
                i += 1
            }
        }
        return slots
    }

    /// Renders one beat slot in the viewer — full chord, or one/two half-width pass chords.
    @ViewBuilder
    private func viewerBeatSlotView(_ slot: [ChordEntry]) -> some View {
        if slot.count == 2 {
            HStack(spacing: 4) {
                viewerHalfChordTile(slot[0])
                viewerHalfChordTile(slot[1])
            }
        } else if slot[0].isPass {
            HStack(spacing: 4) {
                viewerHalfChordTile(slot[0])
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.appBackground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 88)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.appDivider.opacity(0.22),
                                    style: StrokeStyle(lineWidth: 1, dash: [4]))
                    )
            }
        } else {
            viewerChordTile(slot[0])
        }
    }

    /// Half-width read-only tile for a passing chord.
    private func viewerHalfChordTile(_ chord: ChordEntry) -> some View {
        let fnColor = chordFnColor(chord.harmonicFunction)
        return VStack(spacing: 1) {
            Text(chord.romanNumeral)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(fnColor.opacity(0.85))
            Text(chord.chordName(inKey: transposedKey))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.appPrimary.opacity(0.65))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.horizontal, 2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 88)
        .background(fnColor.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(fnColor.opacity(0.35),
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
        )
    }

    private func legendPill(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.appSecondary)
        }
    }

    private func chordFnColor(_ fn: HarmonicFunction) -> Color {
        switch fn {
        case .tonic:       return Color(hex: "#3B82F6")
        case .subdominant: return Color(hex: "#10B981")
        case .dominant:    return Color(hex: "#F59E0B")
        }
    }

    // MARK: - Lyrics Tab

    private var lyricsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let lyrics = song.lyrics, !lyrics.isEmpty {
                LyricsView(lyrics: lyrics, key: transposedKey, transposeSteps: transposeSteps)
                    .padding(.horizontal, 16)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 36))
                        .foregroundColor(.appDivider)
                    Text("No lyrics yet")
                        .font(.appBody)
                        .foregroundColor(.appSecondary)
                    Button {
                        showEditSong = true
                    } label: {
                        Text("Add Lyrics")
                            .font(.appCaption)
                            .foregroundColor(.appAccent)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Notes Tab

    private var notesTab: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let notes = song.notes, !notes.isEmpty {
                Text(notes)
                    .font(.appBody)
                    .foregroundColor(.appPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("No notes")
                    .font(.appBody)
                    .foregroundColor(.appSecondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Lyrics View (chord+lyric display with transpose)

struct LyricsView: View {
    let lyrics: String
    let key: String?
    let transposeSteps: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Parse lyrics lines: lines starting with [ ] contain chord markers
            ForEach(parsedLines, id: \.id) { line in
                if line.isChordLine {
                    chordLineView(line.content)
                        .padding(.top, 8)
                } else if line.isSection {
                    Text(line.content)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.appAccent)
                        .textCase(.uppercase)
                        .tracking(1.5)
                        .padding(.top, 16)
                        .padding(.bottom, 2)
                } else {
                    Text(line.content)
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(.appPrimary)
                }
            }
        }
    }

    private struct LyricLine: Identifiable {
        let id: Int
        let content: String
        let isChordLine: Bool
        let isSection: Bool
    }

    private var parsedLines: [LyricLine] {
        lyrics.components(separatedBy: "\n").enumerated().map { idx, line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let isSection = trimmed.hasPrefix("#") || trimmed.hasPrefix("[Verse") || trimmed.hasPrefix("[Chorus") || trimmed.hasPrefix("[Bridge") || trimmed.hasPrefix("[Pre")
            let isChord = isChordLine(trimmed)
            return LyricLine(id: idx, content: trimmed, isChordLine: isChord, isSection: isSection)
        }
    }

    private func isChordLine(_ line: String) -> Bool {
        let chordPattern = #"^([A-G][#b]?(maj|min|m|aug|dim|sus|add|7|9|11|13|/)?[A-G]?\s*)+"#
        guard let regex = try? NSRegularExpression(pattern: chordPattern) else { return false }
        let range = NSRange(line.startIndex..., in: line)
        return regex.firstMatch(in: line, range: range) != nil && line.count < 60
    }

    private func chordLineView(_ line: String) -> some View {
        let words = line.components(separatedBy: " ")
        return HStack(spacing: 4) {
            ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                if !word.isEmpty {
                    Text(transposeChordToken(word))
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.appAccent)
                }
            }
            Spacer()
        }
    }

    private func transposeChordToken(_ token: String) -> String {
        guard transposeSteps != 0 else { return token }
        let keys = Song.musicalKeys
        // Try to find and transpose the root note
        for keyName in keys.sorted(by: { $0.count > $1.count }) {
            if token.hasPrefix(keyName) {
                let suffix = String(token.dropFirst(keyName.count))
                let transposed = Song.transpose(key: keyName, steps: transposeSteps)
                return transposed + suffix
            }
        }
        return token
    }
}

// MARK: - Song Presenter View (Fullscreen stage mode)

struct SongPresenterView: View {
    let song: Song
    let transposedKey: String?
    @Environment(\.dismiss) var dismiss
    @State private var brightness: Double = UIScreen.main.brightness
    @State private var fontSize: CGFloat = 22

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    // Font size control
                    HStack(spacing: 16) {
                        Button {
                            fontSize = max(14, fontSize - 2)
                        } label: {
                            Image(systemName: "textformat.size.smaller")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Button {
                            fontSize = min(40, fontSize + 2)
                        } label: {
                            Image(systemName: "textformat.size.larger")
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        // Song title & key
                        VStack(alignment: .leading, spacing: 6) {
                            Text(song.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            HStack(spacing: 12) {
                                if let artist = song.artist {
                                    Text(artist)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                if let key = transposedKey {
                                    Text("Key of \(key)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.yellow)
                                }
                                if let bpm = song.tempoBpm {
                                    Text("\(bpm) BPM")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                        .padding(.bottom, 16)

                        // Lyrics
                        if let lyrics = song.lyrics, !lyrics.isEmpty {
                            Text(lyrics)
                                .font(.system(size: fontSize, design: .monospaced))
                                .foregroundColor(.white)
                                .lineSpacing(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("No lyrics available")
                                .font(.system(size: fontSize))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 60)
                }
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
    }
}

// MARK: - Legacy DetailRow (kept for backward compatibility)

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
