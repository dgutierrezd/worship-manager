import SwiftUI

struct CreateServiceView: View {
    @ObservedObject var vm: SetlistViewModel
    @EnvironmentObject var bandVM: BandViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var selectedServiceType = ""
    @State private var includeDate = true
    @State private var date = Date()
    @State private var includeTime = true
    @State private var time = Date()
    @State private var location = ""
    @State private var theme = ""
    @State private var notes = ""
    @State private var isLoading = false

    // MARK: - Setlist picker (songs from library, optional)
    @State private var librarySongs: [Song] = []
    @State private var selectedSongIds: Set<String> = []
    @State private var songSearch: String = ""

    private var filteredLibrary: [Song] {
        guard !songSearch.isEmpty else { return librarySongs }
        return librarySongs.filter {
            $0.title.localizedCaseInsensitiveContains(songSearch) ||
            ($0.artist?.localizedCaseInsensitiveContains(songSearch) ?? false)
        }
    }

    private let serviceTypes: [(id: String, label: String, icon: String)] = [
        ("sunday_morning", "Sunday Morning", "sun.max.fill"),
        ("sunday_evening", "Sunday Evening", "moon.stars.fill"),
        ("wednesday",      "Wednesday",       "calendar.badge.clock"),
        ("special",        "Special Event",   "star.fill")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Name
                    fieldSection(label: "Service Name", icon: "text.cursor") {
                        TextField("e.g. Sunday Morning Service", text: $name)
                            .appTextField()
                    }

                    // Service type grid
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Service Type", systemImage: "tag")
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(serviceTypes, id: \.id) { type in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedServiceType = selectedServiceType == type.id ? "" : type.id
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 13))
                                        Text(type.label)
                                            .font(.system(size: 13, weight: .medium))
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                    }
                                    .foregroundColor(selectedServiceType == type.id ? .white : .appPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 11)
                                    .background(selectedServiceType == type.id ? Color.appPrimary : Color.appSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.appDivider, lineWidth: selectedServiceType == type.id ? 0 : 1)
                                    )
                                }
                            }
                        }
                    }

                    // Date
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle(isOn: $includeDate) {
                            Label("Set Date", systemImage: "calendar")
                                .font(.appCaption)
                                .foregroundColor(.appSecondary)
                        }
                        .tint(.appAccent)

                        if includeDate {
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .tint(.appAccent)
                        }
                    }

                    // Time
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle(isOn: $includeTime) {
                            Label("Set Time", systemImage: "clock")
                                .font(.appCaption)
                                .foregroundColor(.appSecondary)
                        }
                        .tint(.appAccent)

                        if includeTime {
                            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .tint(.appAccent)
                        }
                    }

                    // Location
                    fieldSection(label: "Location (optional)", icon: "mappin.circle") {
                        TextField("Main Sanctuary", text: $location)
                            .appTextField()
                    }

                    // Theme
                    fieldSection(label: "Theme (optional)", icon: "sparkles") {
                        TextField("e.g. Grace, Hope, Renewal...", text: $theme)
                            .appTextField()
                    }

                    // Songs (the setlist) — optional, build it now or later
                    songsPickerSection

                    // Notes
                    fieldSection(label: "Notes (optional)", icon: "note.text") {
                        TextField("Additional notes...", text: $notes, axis: .vertical)
                            .appTextField()
                            .lineLimit(3...6)
                    }
                }
                .padding(24)
            }
            .task { await loadLibrary() }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("New Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Create") {
                            Task { await create() }
                        }
                        .fontWeight(.semibold)
                        .disabled(name.isEmpty)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func fieldSection<Content: View>(label: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.appCaption)
                .foregroundColor(.appSecondary)
            content()
        }
    }

    // MARK: - Songs Picker

    /// Optional inline picker that lets the user build the service's
    /// setlist while creating it. Selected songs are added in order
    /// after the setlist is created.
    private var songsPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("setlist_optional".localized, systemImage: "music.note.list")
                    .font(.appCaption)
                    .foregroundColor(.appSecondary)
                Spacer()
                if !selectedSongIds.isEmpty {
                    Text("\(selectedSongIds.count) " + "selected".localized)
                        .font(.appSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(.appAccent)
                }
            }

            if librarySongs.isEmpty {
                Text("no_songs_in_library_hint".localized)
                    .font(.appCaption)
                    .foregroundColor(.appSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.appDivider, lineWidth: 1)
                    )
            } else {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.appSecondary)
                            .font(.system(size: 13))
                        TextField("search_songs".localized, text: $songSearch)
                            .font(.appBody)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.appDivider, lineWidth: 1)
                    )

                    LazyVStack(spacing: 0) {
                        ForEach(filteredLibrary) { song in
                            Button {
                                AppHaptics.selection()
                                if selectedSongIds.contains(song.id) {
                                    selectedSongIds.remove(song.id)
                                } else {
                                    selectedSongIds.insert(song.id)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: selectedSongIds.contains(song.id)
                                          ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedSongIds.contains(song.id) ? .appAccent : .appDivider)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(song.title)
                                            .font(.appHeadline)
                                            .foregroundColor(.appPrimary)
                                            .lineLimit(1)
                                        if let artist = song.artist {
                                            Text(artist)
                                                .font(.appCaption)
                                                .foregroundColor(.appSecondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    if let key = song.defaultKey { KeyBadge(key: key) }
                                }
                                .padding(.vertical, 9)
                                .padding(.horizontal, 12)
                            }
                            .buttonStyle(.plain)
                            if song.id != filteredLibrary.last?.id {
                                Divider().opacity(0.4)
                            }
                        }
                    }
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.appDivider, lineWidth: 1)
                    )
                }
            }
        }
    }

    private func loadLibrary() async {
        guard let bandId = bandVM.currentBand?.id else { return }
        do {
            librarySongs = try await SongService.getSongs(bandId: bandId)
        } catch {
            // Non-fatal — picker just shows the empty hint.
        }
    }

    private func create() async {
        isLoading = true
        defer { isLoading = false }

        let dateStr: String? = includeDate ? {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: date)
        }() : nil

        let timeStr: String? = includeTime ? {
            let f = DateFormatter()
            f.dateFormat = "HH:mm:ss"
            return f.string(from: time)
        }() : nil

        let created = await vm.createSetlist(
            name: name,
            date: dateStr,
            time: timeStr,
            notes: notes.isEmpty ? nil : notes,
            serviceType: selectedServiceType.isEmpty ? nil : selectedServiceType,
            location: location.isEmpty ? nil : location,
            theme: theme.isEmpty ? nil : theme
        )

        // If the user picked songs, attach them in the order shown in the
        // library (alphabetical). The backend assigns positions sequentially.
        if let created, !selectedSongIds.isEmpty {
            let orderedIds = librarySongs.compactMap { song -> String? in
                selectedSongIds.contains(song.id) ? song.id : nil
            }
            for songId in orderedIds {
                _ = try? await SetlistService.addSongToSetlist(
                    setlistId: created.id, songId: songId, keyOverride: nil, notes: nil
                )
            }
        }
        dismiss()
    }
}
