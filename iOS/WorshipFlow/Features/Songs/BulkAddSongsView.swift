import SwiftUI

// MARK: - Bulk Add Songs
//
// Lets the user paste a list of songs (one per line) to seed the band's
// library quickly. Each line is parsed as `Title - Artist` (or just `Title`).
// Common separators understood: ` - `, ` — `, ` – `, ` by `.

struct BulkAddSongsView: View {
    @ObservedObject var vm: SongsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var rawText: String = ""
    @State private var parsed: [BulkSongLine] = []
    @State private var addedCount: Int? = nil
    @State private var localError: String? = nil

    private var validCount: Int { parsed.filter { !$0.title.isEmpty }.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {

                    // Helper card
                    helperCard

                    // Editor
                    VStack(alignment: .leading, spacing: 8) {
                        Label("songs_one_per_line".localized, systemImage: "text.alignleft")
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)

                        TextEditor(text: $rawText)
                            .font(.system(size: 15, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(minHeight: 240)
                            .background(Color.appSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.appDivider, lineWidth: 1.2)
                            )
                            .onChange(of: rawText) { _, newValue in
                                parsed = BulkSongLine.parse(newValue)
                            }
                    }

                    // Preview
                    if !parsed.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("preview".localized, systemImage: "eye")
                                    .font(.appCaption)
                                    .foregroundColor(.appSecondary)
                                Spacer()
                                Text("\(validCount) " + "songs".localized)
                                    .font(.appSmall)
                                    .foregroundColor(.appAccent)
                                    .fontWeight(.semibold)
                            }

                            VStack(spacing: 0) {
                                ForEach(parsed) { line in
                                    PreviewRow(line: line)
                                    if line.id != parsed.last?.id {
                                        Divider().opacity(0.5)
                                    }
                                }
                            }
                            .background(Color.appSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.appDivider, lineWidth: 1)
                            )
                        }
                    }

                    if let localError {
                        Text(localError)
                            .font(.appCaption)
                            .foregroundColor(.statusNo)
                    }
                    if let addedCount {
                        Label(
                            String(format: "added_n_songs".localized, addedCount),
                            systemImage: "checkmark.circle.fill"
                        )
                        .font(.appCaption)
                        .foregroundColor(.statusGoing)
                    }
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("bulk_add_songs".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if vm.isBulkLoading {
                        ProgressView()
                    } else {
                        Button("add_n".localizedFormat(validCount)) {
                            Task { await save() }
                        }
                        .disabled(validCount == 0)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    // MARK: - Helper Card

    private var helperCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appAccent)
                Text("bulk_add_hint_title".localized)
                    .font(.appHeadline)
                    .foregroundColor(.appPrimary)
            }
            Text("bulk_add_hint_body".localized)
                .font(.appCaption)
                .foregroundColor(.appSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Example block
            VStack(alignment: .leading, spacing: 4) {
                Text("Goodness of God - Bethel")
                Text("Way Maker - Sinach")
                Text("Build My Life")
            }
            .font(.system(size: 13, design: .monospaced))
            .foregroundColor(.appSecondary)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .background(Color.appAccent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Save

    private func save() async {
        localError = nil
        addedCount = nil
        let entries = parsed
            .filter { !$0.title.isEmpty }
            .map { (title: $0.title, artist: $0.artist) }
        guard !entries.isEmpty else { return }

        if let n = await vm.bulkAddSongs(entries) {
            addedCount = n
            // brief confirmation, then close
            try? await Task.sleep(nanoseconds: 700_000_000)
            dismiss()
        } else {
            localError = vm.error ?? "bulk_add_failed".localized
        }
    }
}

// MARK: - Preview Row

private struct PreviewRow: View {
    let line: BulkSongLine

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: line.title.isEmpty ? "minus.circle" : "music.note")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(line.title.isEmpty ? .appDivider : .appAccent)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(line.title.isEmpty ? "(empty)" : line.title)
                    .font(.appHeadline)
                    .foregroundColor(line.title.isEmpty ? .appSecondary : .appPrimary)
                    .lineLimit(1)
                if let artist = line.artist, !artist.isEmpty {
                    Text(artist)
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Parsing

struct BulkSongLine: Identifiable {
    let id = UUID()
    let title: String
    let artist: String?

    /// Parse a multi-line text blob into structured song entries.
    /// Recognised separators: ` - `, ` — `, ` – `, ` by ` (case-insensitive).
    /// Empty lines are dropped.
    static func parse(_ text: String) -> [BulkSongLine] {
        text
            .split(whereSeparator: \.isNewline)
            .map { String($0) }
            .map { line -> String in line.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { Self.parseLine($0) }
    }

    private static func parseLine(_ line: String) -> BulkSongLine {
        let separators = [" — ", " – ", " - ", " by "]
        for sep in separators {
            if let range = line.range(of: sep, options: .caseInsensitive) {
                let title = String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let artist = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                return BulkSongLine(title: title, artist: artist.isEmpty ? nil : artist)
            }
        }
        return BulkSongLine(title: line, artist: nil)
    }
}

// MARK: - Localized Format Helper

private extension String {
    /// Returns the localized template applied with the given int (e.g. "Add %d").
    func localizedFormat(_ value: Int) -> String {
        String(format: self.localized, value)
    }
}
