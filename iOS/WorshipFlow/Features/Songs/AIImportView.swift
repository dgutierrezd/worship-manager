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
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(.appAccent)
                Text("ai_import_loading".localized)
                    .font(.appCaption)
                    .foregroundColor(.appSecondary)
            }
            .padding(.vertical, 16)

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
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 14) {
                // Selection toggle
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(isSelected ? .appAccent : .appDivider)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 6) {
                    // Title + Key
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

                    // Artist + Tempo + Status
                    HStack(spacing: 8) {
                        if let artist = result.artist {
                            Text(artist)
                                .font(.appBody)
                                .foregroundColor(.appSecondary)
                                .lineLimit(1)
                        }

                        if let tempo = result.tempoBpm {
                            Text("\(tempo) BPM")
                                .font(.appCaption)
                                .foregroundColor(.appSecondary)
                        }

                        Spacer()

                        if !result.found {
                            Text("ai_import_not_found".localized)
                                .font(.appCaption)
                                .foregroundColor(.statusNo)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.statusNo.opacity(0.1))
                                .clipShape(Capsule())
                        } else if let sections = result.chordSections, !sections.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 10))
                                Text("\(sections.count) sections")
                                    .font(.appCaption)
                            }
                            .foregroundColor(.appAccent)
                        }
                    }
                }
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .cardStyle()
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
