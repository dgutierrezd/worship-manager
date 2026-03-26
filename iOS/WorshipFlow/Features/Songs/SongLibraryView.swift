import SwiftUI

// MARK: - Song Library View (OnStage-inspired)

struct SongLibraryView: View {
    @EnvironmentObject var bandVM: BandViewModel
    @StateObject private var vm = SongsViewModel()

    @State private var searchText = ""
    @State private var selectedKey: String? = nil
    @State private var selectedTheme: String? = nil
    @State private var sortOption: SortOption = .alphabetical
    @State private var showAddSong = false
    @State private var showFilters = false
    @State private var showAIImport = false

    enum SortOption: String, CaseIterable {
        case alphabetical = "A–Z"
        case recentlyAdded = "Recent"
        case mostUsed = "Most Used"
    }

    // MARK: - Filtering & Sorting

    var allKeys: [String] {
        let keys = vm.songs.compactMap { $0.defaultKey }
        return Array(Set(keys)).sorted()
    }

    var allThemes: [String] {
        let themes = vm.songs.compactMap { $0.theme }.filter { !$0.isEmpty }
        return Array(Set(themes)).sorted()
    }

    var filteredSongs: [Song] {
        var result = vm.songs

        // Search
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.artist?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.theme?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.tags?.joined(separator: " ").localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Key filter
        if let key = selectedKey {
            result = result.filter { $0.defaultKey == key }
        }

        // Theme filter
        if let theme = selectedTheme {
            result = result.filter { $0.theme == theme }
        }

        // Sort
        switch sortOption {
        case .alphabetical:
            result.sort { $0.title.lowercased() < $1.title.lowercased() }
        case .recentlyAdded:
            result.sort { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
        case .mostUsed:
            result.sort { ($0.timesUsed ?? 0) > ($1.timesUsed ?? 0) }
        }

        return result
    }

    var isFiltered: Bool { selectedKey != nil || selectedTheme != nil }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar

                Divider().opacity(0.5)

                if vm.isLoading && vm.songs.isEmpty {
                    // Skeleton while loading for the first time
                    List {
                        SkeletonList(count: 8) { SkeletonSongRow() }
                            .listRowBackground(Color.appSurface)
                            .listRowSeparatorTint(Color.appDivider)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .allowsHitTesting(false)
                } else if vm.songs.isEmpty {
                    EmptyStateView(
                        icon: "🎵",
                        title: "No songs yet",
                        subtitle: "Add your first song to get started",
                        buttonTitle: "new_song".localized
                    ) {
                        showAddSong = true
                    }
                } else if filteredSongs.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.appDivider)
                        Text("No songs match your filters")
                            .font(.appBody)
                            .foregroundColor(.appSecondary)
                        Button {
                            selectedKey = nil
                            selectedTheme = nil
                            searchText = ""
                        } label: {
                            Text("Clear Filters")
                                .font(.appCaption)
                                .foregroundColor(.appAccent)
                        }
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredSongs) { song in
                            NavigationLink {
                                SongDetailView(song: song)
                                    .environmentObject(vm)
                            } label: {
                                SongRow(song: song)
                            }
                            .listRowBackground(Color.appSurface)
                        }
                        .onDelete { indexSet in
                            Task {
                                for idx in indexSet {
                                    await vm.deleteSong(filteredSongs[idx])
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .searchable(text: $searchText, prompt: "Search songs, artist, theme…")
                }
            }
            .background(Color.appBackground)
            .navigationTitle("songs".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 4) {
                        Button {
                            showAIImport = true
                        } label: {
                            Image(systemName: "sparkles")
                                .fontWeight(.semibold)
                        }
                        Button {
                            showAddSong = true
                        } label: {
                            Image(systemName: "plus")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddSong) {
                AddSongView(vm: vm)
            }
            .sheet(isPresented: $showAIImport) {
                AIImportView(vm: vm)
            }
            .refreshable {
                guard let bandId = bandVM.currentBand?.id else { return }
                await vm.loadSongs(bandId: bandId)
            }
            .task {
                guard let bandId = bandVM.currentBand?.id else { return }
                await vm.loadSongs(bandId: bandId)
            }
        }
        .background(Color.appBackground)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {

                // Sort menu
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button {
                            sortOption = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 11))
                        Text(sortOption.rawValue)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.appPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.appSurface)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.appDivider, lineWidth: 1))
                }

                Divider()
                    .frame(height: 20)
                    .opacity(0.5)

                // Key chips
                if !allKeys.isEmpty {
                    ForEach(allKeys, id: \.self) { key in
                        FilterChip(
                            label: key,
                            isSelected: selectedKey == key
                        ) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedKey = selectedKey == key ? nil : key
                            }
                        }
                    }
                }

                // Theme chips
                if !allThemes.isEmpty {
                    Divider()
                        .frame(height: 20)
                        .opacity(0.5)

                    ForEach(allThemes, id: \.self) { theme in
                        FilterChip(
                            label: theme,
                            icon: "sparkles",
                            isSelected: selectedTheme == theme
                        ) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedTheme = selectedTheme == theme ? nil : theme
                            }
                        }
                    }
                }

                // Clear all filters
                if isFiltered {
                    Button {
                        withAnimation {
                            selectedKey = nil
                            selectedTheme = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.appSecondary)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                }
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .appPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isSelected ? Color.appPrimary : Color.appSurface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.appDivider, lineWidth: isSelected ? 0 : 1))
        }
    }
}

// MARK: - Song Row (improved)

struct SongRow: View {
    let song: Song

    var body: some View {
        HStack(spacing: 12) {
            // Music note icon with key color
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(song.defaultKey != nil ? Color.appPrimary.opacity(0.08) : Color.appDivider.opacity(0.4))
                    .frame(width: 44, height: 44)
                Image(systemName: "music.note")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(song.defaultKey != nil ? .appPrimary : .appSecondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.appHeadline)
                    .foregroundColor(.appPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let artist = song.artist {
                        Text(artist)
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)
                            .lineLimit(1)
                    }
                    if let dur = song.formattedDuration {
                        Text(dur)
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)
                    }
                    if let theme = song.theme, !theme.isEmpty {
                        Text(theme)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.appAccent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appAccent.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            if let key = song.defaultKey {
                KeyBadge(key: key)
            }
        }
        .padding(.vertical, 4)
    }
}
