import SwiftUI

// MARK: - Lyric Chord Editor View

struct LyricChordEditorView: View {
    let song: Song
    @ObservedObject var vm: SongsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var lines: [AnnotatedLine] = []
    @State private var activeEdit: ChordEditTarget?
    @State private var chordInput = ""
    @State private var isSaving = false

    private var songKey: String? { song.defaultKey }

    init(song: Song, vm: SongsViewModel) {
        self.song = song
        self._vm = ObservedObject(wrappedValue: vm)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        if lines.isEmpty {
                            emptyState
                        } else {
                            ForEach(lines.indices, id: \.self) { lineIdx in
                                lineView(lineIdx: lineIdx)
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 120)
                }

                // Bottom chord palette
                chordPalette
            }
            .background(Color.appBackground)
            .navigationTitle("edit_chord_chart".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) { dismiss() }
                        .foregroundColor(.appSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving {
                        ProgressView().tint(.appAccent)
                    } else {
                        Button("save".localized) { Task { await save() } }
                            .fontWeight(.semibold)
                            .foregroundColor(.appAccent)
                    }
                }
            }
            .onAppear { parseExistingLyrics() }
        }
    }

    // MARK: - Line View

    @ViewBuilder
    private func lineView(lineIdx: Int) -> some View {
        let line = lines[lineIdx]

        if line.isSection {
            Text(line.sectionName ?? "")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.appAccent)
                .textCase(.uppercase)
                .tracking(1.5)
                .padding(.top, 16)
                .padding(.bottom, 4)
        } else if line.isEmpty {
            Spacer().frame(height: 12)
        } else {
            // Lyric line with tappable words
            FlowLayout(spacing: 0) {
                ForEach(line.words.indices, id: \.self) { wordIdx in
                    wordView(lineIdx: lineIdx, wordIdx: wordIdx)
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Word View

    private func wordView(lineIdx: Int, wordIdx: Int) -> some View {
        let word = lines[lineIdx].words[wordIdx]
        let isActive = activeEdit?.lineIdx == lineIdx && activeEdit?.wordIdx == wordIdx

        return Button {
            if isActive {
                // Deselect
                commitChordEdit()
            } else {
                // Select this word for chord editing
                commitChordEdit()
                chordInput = word.chord ?? ""
                activeEdit = ChordEditTarget(lineIdx: lineIdx, wordIdx: wordIdx)
            }
        } label: {
            VStack(spacing: 0) {
                // Chord above
                if isActive {
                    chordInputField
                        .transition(.scale.combined(with: .opacity))
                } else if let chord = word.chord, !chord.isEmpty {
                    Text(chord)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.appAccent)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.appAccent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    // Invisible placeholder to keep layout consistent
                    Text(" ")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .padding(.vertical, 2)
                }

                // The word
                Text(word.text)
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.appPrimary)
            }
            .padding(.horizontal, 1)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isActive ? Color.appAccent.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Chord Input Field

    private var chordInputField: some View {
        TextField("chord".localized, text: $chordInput)
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundColor(.appAccent)
            .multilineTextAlignment(.center)
            .frame(minWidth: 40, maxWidth: 80)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.appAccent.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.appAccent, lineWidth: 1.5)
            )
            .onSubmit { commitChordEdit() }
    }

    // MARK: - Chord Palette

    private var chordPalette: some View {
        VStack(spacing: 8) {
            Divider()

            if activeEdit != nil {
                // Show delete button when editing
                HStack {
                    Text("tap_word_to_place_chord".localized)
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)
                    Spacer()
                    Button {
                        chordInput = ""
                        commitChordEdit()
                    } label: {
                        Label("remove".localized, systemImage: "xmark.circle.fill")
                            .font(.appCaption)
                            .foregroundColor(.statusNo)
                    }
                }
                .padding(.horizontal, 16)
            }

            // Diatonic chord buttons
            if let key = songKey {
                VStack(alignment: .leading, spacing: 6) {
                    Text("KEY_OF".localized + " \(key)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.appSecondary)
                        .tracking(1)
                        .padding(.horizontal, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(1...7, id: \.self) { degree in
                                let entry = ChordEntry(degree: degree)
                                let chordName = entry.chordName(inKey: key)
                                Button {
                                    insertChordFromPalette(chordName)
                                } label: {
                                    VStack(spacing: 2) {
                                        Text(entry.romanNumeral)
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(paletteColor(entry.harmonicFunction))
                                        Text(chordName)
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundColor(.appPrimary)
                                    }
                                    .frame(width: 52, height: 46)
                                    .background(paletteColor(entry.harmonicFunction).opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(paletteColor(entry.harmonicFunction).opacity(0.25), lineWidth: 1)
                                    )
                                }
                            }

                            // Common extras: 7ths
                            ForEach(commonExtras(inKey: key), id: \.self) { chord in
                                Button {
                                    insertChordFromPalette(chord)
                                } label: {
                                    Text(chord)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(.appPrimary)
                                        .frame(width: 52, height: 46)
                                        .background(Color.appSurface)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.appDivider, lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            } else {
                // No key set — show chromatic roots
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Song.musicalKeys, id: \.self) { root in
                            Button {
                                insertChordFromPalette(root)
                            } label: {
                                Text(root)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.appPrimary)
                                    .frame(width: 44, height: 44)
                                    .background(Color.appSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.appDivider, lineWidth: 1)
                                    )
                            }
                        }

                        ForEach(["m", "7", "m7", "sus4"], id: \.self) { suffix in
                            Button {
                                chordInput += suffix
                            } label: {
                                Text(suffix)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.appSecondary)
                                    .frame(width: 44, height: 44)
                                    .background(Color.appBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.appDivider, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 10)
        .background(Color.appSurface)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.alignleft")
                .font(.system(size: 44))
                .foregroundColor(.appDivider)
            Text("no_lyrics_to_annotate".localized)
                .font(.appHeadline)
                .foregroundColor(.appSecondary)
            Text("add_lyrics_first".localized)
                .font(.appCaption)
                .foregroundColor(.appSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(48)
    }

    // MARK: - Helpers

    private func paletteColor(_ fn: HarmonicFunction) -> Color {
        switch fn {
        case .tonic:       return Color(hex: "#3B82F6")
        case .subdominant: return Color(hex: "#10B981")
        case .dominant:    return Color(hex: "#F59E0B")
        }
    }

    private func commonExtras(inKey key: String) -> [String] {
        // Common 7th chords
        let v7 = ChordEntry(degree: 5, modifier: "7").chordName(inKey: key)
        let ii7 = ChordEntry(degree: 2, modifier: "7").chordName(inKey: key)
        let ivmaj7 = ChordEntry(degree: 4, modifier: "maj7").chordName(inKey: key)
        return [v7, ii7, ivmaj7]
    }

    private func insertChordFromPalette(_ chord: String) {
        if activeEdit != nil {
            chordInput = chord
            commitChordEdit()
        }
    }

    private func commitChordEdit() {
        guard let target = activeEdit else { return }
        guard target.lineIdx < lines.count,
              target.wordIdx < lines[target.lineIdx].words.count else {
            activeEdit = nil
            chordInput = ""
            return
        }
        let trimmed = chordInput.trimmingCharacters(in: .whitespaces)
        lines[target.lineIdx].words[target.wordIdx].chord = trimmed.isEmpty ? nil : trimmed
        activeEdit = nil
        chordInput = ""
    }

    // MARK: - Parse / Serialize

    private func parseExistingLyrics() {
        guard let lyrics = song.lyrics, !lyrics.isEmpty else {
            lines = []
            return
        }

        lines = lyrics.components(separatedBy: "\n").map { rawLine in
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)

            // Section headers
            if isSectionHeader(trimmed) {
                let name = trimmed
                    .replacingOccurrences(of: "#", with: "")
                    .replacingOccurrences(of: "[", with: "")
                    .replacingOccurrences(of: "]", with: "")
                    .trimmingCharacters(in: .whitespaces)
                return AnnotatedLine(words: [], isSection: true, sectionName: name, isEmpty: false)
            }

            // Empty lines
            if trimmed.isEmpty {
                return AnnotatedLine(words: [], isSection: false, sectionName: nil, isEmpty: true)
            }

            // Parse words with [chord] markers
            let words = parseWordsWithChords(trimmed)
            return AnnotatedLine(words: words, isSection: false, sectionName: nil, isEmpty: false)
        }
    }

    private func parseWordsWithChords(_ line: String) -> [AnnotatedWord] {
        var result: [AnnotatedWord] = []
        var remaining = line[line.startIndex...]
        var currentChord: String?

        while !remaining.isEmpty {
            // Check for [chord] marker
            if remaining.hasPrefix("[") {
                if let closeBracket = remaining.firstIndex(of: "]") {
                    let chordContent = String(remaining[remaining.index(after: remaining.startIndex)..<closeBracket])
                    if isChordName(chordContent) {
                        currentChord = chordContent
                        remaining = remaining[remaining.index(after: closeBracket)...]
                        continue
                    }
                }
            }

            // Extract next word (space-delimited)
            let wordEnd: String.Index
            if let spaceIdx = remaining.firstIndex(of: " ") {
                wordEnd = spaceIdx
            } else {
                wordEnd = remaining.endIndex
            }

            let wordText = String(remaining[remaining.startIndex..<wordEnd])
            if !wordText.isEmpty {
                result.append(AnnotatedWord(text: wordText + " ", chord: currentChord))
                currentChord = nil
            }

            if wordEnd < remaining.endIndex {
                remaining = remaining[remaining.index(after: wordEnd)...]
            } else {
                break
            }
        }

        // Handle trailing chord with no word after it
        if let chord = currentChord {
            if result.isEmpty {
                result.append(AnnotatedWord(text: " ", chord: chord))
            } else {
                // Attach to last word if there's a dangling chord
                result[result.count - 1].chord = chord
            }
        }

        return result
    }

    private func isSectionHeader(_ line: String) -> Bool {
        if line.hasPrefix("#") { return true }
        let sectionPattern = #"^\[(Verse|Chorus|Bridge|Pre-Chorus|Intro|Outro|Instrumental|Tag|Hook|Interlude|Ending)"#
        return (try? NSRegularExpression(pattern: sectionPattern, options: .caseInsensitive))
            .flatMap { $0.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) } != nil
    }

    private func isChordName(_ text: String) -> Bool {
        let pattern = #"^[A-G][#b]?(m|min|maj|dim|aug|sus[24]?|add[0-9]+|[0-9]+)*(/[A-G][#b]?)?$"#
        return (try? NSRegularExpression(pattern: pattern))
            .flatMap { $0.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) } != nil
    }

    private func serializeToLyrics() -> String {
        lines.map { line in
            if line.isSection {
                return "[\(line.sectionName ?? "")]"
            }
            if line.isEmpty {
                return ""
            }
            return line.words.map { word in
                let chordPrefix = word.chord.map { "[\($0)]" } ?? ""
                return chordPrefix + word.text.trimmingCharacters(in: .init(charactersIn: " "))
            }.joined(separator: " ")
        }.joined(separator: "\n")
    }

    // MARK: - Save

    private func save() async {
        commitChordEdit()
        isSaving = true
        let newLyrics = serializeToLyrics()
        let _ = await vm.updateSong(
            song,
            title: song.title,
            artist: song.artist,
            key: song.defaultKey,
            tempo: song.tempoBpm,
            duration: song.durationSec,
            notes: song.notes,
            lyrics: newLyrics,
            tags: song.tags,
            theme: song.theme,
            youtubeUrl: song.youtubeUrl,
            spotifyUrl: song.spotifyUrl
        )
        isSaving = false
        dismiss()
    }
}

// MARK: - Supporting Types

private struct ChordEditTarget {
    let lineIdx: Int
    let wordIdx: Int
}

private struct AnnotatedLine {
    var words: [AnnotatedWord]
    var isSection: Bool
    var sectionName: String?
    var isEmpty: Bool
}

private struct AnnotatedWord {
    var text: String
    var chord: String?
}
