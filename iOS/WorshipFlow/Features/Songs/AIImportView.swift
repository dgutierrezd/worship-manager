import SwiftUI

// MARK: - AI Import View

struct AIImportView: View {
    @ObservedObject var vm: SongsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var inputText = ""
    @State private var selectedIds: Set<String> = []
    @State private var hasSearched = false

    private var selectedSongs: [AISongResult] {
        vm.aiResults.filter { selectedIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if vm.isAILoading {
                    loadingView
                } else if hasSearched {
                    resultsSection
                } else {
                    inputSection
                }
            }
            .background(Color.appBackground)
            .navigationTitle("ai_import_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) {
                        vm.aiResults = []
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("ai_import_title".localized)
                    .font(.appHeadline)
                    .foregroundColor(.appPrimary)

                Text("ai_import_instructions".localized)
                    .font(.appCaption)
                    .foregroundColor(.appSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $inputText)
                    .font(.appBody)
                    .foregroundColor(.appPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 160, maxHeight: 240)
                    .padding(14)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appDivider, lineWidth: 1)
                    )

                if inputText.isEmpty {
                    Text("ai_import_placeholder".localized)
                        .font(.appBody)
                        .foregroundColor(.appSecondary.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.top, 22)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 16)

            if let errorMsg = vm.error {
                Text(errorMsg)
                    .font(.appCaption)
                    .foregroundColor(.statusNo)
                    .padding(.horizontal, 16)
            }

            Spacer()

            Button {
                Task { await performSearch() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("ai_import_search".localized)
                }
            }
            .primaryButton()
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            // Animated Claude indicator
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.12))
                        .frame(width: 56, height: 56)
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppGradients.gold)
                }
                Text("Asking Claude AI…")
                    .font(.appHeadline)
                    .foregroundColor(.appPrimary)
                Text("Looking up songs, chords, lyrics & links")
                    .font(.appCaption)
                    .foregroundColor(.appSecondary)
            }
            .padding(.top, 24)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { _ in
                        SkeletonAICard()
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 8)
            }
            .allowsHitTesting(false)
        }
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        VStack(spacing: 0) {
            // Results list
            ScrollView {
                VStack(spacing: 12) {
                    if vm.aiResults.isEmpty {
                        EmptyStateView(
                            icon: "🔍",
                            title: "ai_import_no_results".localized,
                            subtitle: "ai_import_try_again".localized
                        )
                        .padding(.top, 40)
                    } else {
                        ForEach(vm.aiResults) { result in
                            AIResultCard(
                                result: result,
                                isSelected: selectedIds.contains(result.id)
                            ) {
                                toggleSelection(result)
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.vertical, 12)
            }

            // Bottom action bar
            VStack(spacing: 10) {
                Divider()

                if let errorMsg = vm.error {
                    Text(errorMsg)
                        .font(.appCaption)
                        .foregroundColor(.statusNo)
                        .padding(.horizontal, 16)
                }

                HStack(spacing: 12) {
                    Button {
                        hasSearched = false
                        vm.aiResults = []
                        selectedIds = []
                        vm.error = nil
                    } label: {
                        Text("ai_import_search".localized)
                    }
                    .secondaryButton()

                    Button {
                        Task { await importSelected() }
                    } label: {
                        Text(String(format: "ai_import_button".localized, selectedIds.count))
                    }
                    .primaryButton()
                    .disabled(selectedIds.isEmpty)
                    .opacity(selectedIds.isEmpty ? 0.5 : 1)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color.appBackground)
        }
    }

    // MARK: - Actions

    private func performSearch() async {
        let names = inputText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !names.isEmpty else { return }

        hasSearched = true
        await vm.aiLookup(names: Array(names.prefix(10)))

        // If lookup failed, drop back to input screen so the error is visible
        if vm.error != nil {
            hasSearched = false
            return
        }

        // Auto-select all recognized songs after lookup
        selectedIds = Set(vm.aiResults.filter { $0.found }.map { $0.id })
    }

    private func toggleSelection(_ result: AISongResult) {
        if selectedIds.contains(result.id) {
            selectedIds.remove(result.id)
        } else {
            selectedIds.insert(result.id)
        }
    }

    private func importSelected() async {
        let toImport = vm.aiResults.filter { selectedIds.contains($0.id) }
        guard !toImport.isEmpty else { return }
        await vm.aiImport(songs: toImport)
        if vm.error == nil {
            dismiss()
        }
    }
}

// MARK: - AI Result Card

struct AIResultCard: View {
    let result: AISongResult
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: {
            AppHaptics.selection()
            onToggle()
        }) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 14) {
                    // Selection circle
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.appAccent : Color.appDivider.opacity(0.5))
                            .frame(width: 26, height: 26)
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)

                    VStack(alignment: .leading, spacing: 6) {
                        // Title row
                        HStack(alignment: .center) {
                            Text(result.title)
                                .font(.appHeadline)
                                .foregroundColor(.appPrimary)
                                .lineLimit(1)
                            Spacer()
                            if let key = result.defaultKey {
                                KeyBadge(key: key)
                            }
                        }

                        // Artist + BPM
                        HStack(spacing: 6) {
                            if let artist = result.artist {
                                Text(artist)
                                    .font(.appBody)
                                    .foregroundColor(.appSecondary)
                                    .lineLimit(1)
                            }
                            if let bpm = result.tempoBpm {
                                Text("·")
                                    .foregroundColor(.appDivider)
                                Text("\(bpm) BPM")
                                    .font(.appCaption)
                                    .foregroundColor(.appSecondary)
                            }
                            Spacer()
                        }

                        // Data indicators or "not found" badge
                        if !result.found {
                            HStack(spacing: 5) {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 11))
                                Text("ai_import_not_found".localized)
                                    .font(.appSmall)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.statusNo)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Color.statusNo.opacity(0.10))
                            .clipShape(Capsule())
                        } else {
                            HStack(spacing: 8) {
                                if result.hasChords, let sections = result.chordSections {
                                    DataPill(icon: "music.note.list",
                                             label: "\(sections.count) sections",
                                             color: .featureSongs)
                                }
                                if result.hasLyrics {
                                    DataPill(icon: "text.alignleft",
                                             label: "Lyrics",
                                             color: .featureSchedule)
                                }
                                if result.youtubeUrl != nil {
                                    DataPill(icon: "play.rectangle.fill",
                                             label: "YouTube",
                                             color: .statusNo)
                                }
                                if result.spotifyUrl != nil {
                                    DataPill(icon: "music.quarternote.3",
                                             label: "Spotify",
                                             color: .statusGoing)
                                }
                            }
                        }
                    }
                }
                .padding(16)

                // Gold accent bottom bar when selected
                if isSelected {
                    AppGradients.gold
                        .frame(height: 3)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 0)
                                .corners([.bottomLeft, .bottomRight], radius: 18)
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    isSelected ? Color.appAccent.opacity(0.50) : Color.appDivider,
                    lineWidth: isSelected ? 1.5 : 1
                )
        )
        .shadow(color: isSelected ? Color.appAccent.opacity(0.12) : .black.opacity(0.04),
                radius: isSelected ? 10 : 6, x: 0, y: 2)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Data Pill

private struct DataPill: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
            Text(label)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.10))
        .clipShape(Capsule())
    }
}

// MARK: - Rounded corner helper

private extension Shape where Self == RoundedRectangle {
    func corners(_ corners: UIRectCorner, radius: CGFloat) -> some Shape {
        self // RoundedRectangle already handles corners; kept for API symmetry
    }
}

// MARK: - Skeleton AI Card

struct SkeletonAICard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            SkeletonBlock(width: 22, height: 22, cornerRadius: 11)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    SkeletonBlock(width: CGFloat.random(in: 120...200), height: 16)
                    Spacer()
                    SkeletonBlock(width: 36, height: 22, cornerRadius: 8)
                }
                HStack {
                    SkeletonBlock(width: CGFloat.random(in: 80...150), height: 12)
                    Spacer()
                }
            }
        }
        .padding(16)
        .cardStyle()
    }
}
