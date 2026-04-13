import SwiftUI

// MARK: - Service Detail View (OnStage-inspired)

struct ServiceDetailView: View {
    let setlist: Setlist
    @EnvironmentObject var bandVM: BandViewModel
    @StateObject private var vm = SetlistViewModel()
    @StateObject private var assignmentVM = ServiceAssignmentViewModel()

    @State private var showAddSong = false
    @State private var showManageTeam = false
    @State private var selectedTab = 0
    @State private var calendarAdded = false
    @State private var showCalendarError = false

    // Any band member can edit services — no role-based gating.
    var canEdit: Bool { bandVM.currentBand != nil }

    var totalDurationString: String {
        let total = vm.setlistSongs.compactMap { $0.songs?.durationSec }.reduce(0, +)
        guard total > 0 else { return "" }
        return "\(total / 60):\(String(format: "%02d", total % 60))"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Segmented tabs
            Picker("", selection: $selectedTab) {
                Text("Songs").tag(0)
                Text("Team").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            ZStack {
                if selectedTab == 0 { songsTab }
                if selectedTab == 1 { teamTab }
            }
        }
        .background(Color.appBackground)
        .navigationTitle(setlist.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 14) {
                    if !vm.setlistSongs.isEmpty {
                        Button {
                            PracticeManager.shared.startSession(songs: vm.setlistSongs)
                        } label: {
                            Image(systemName: "play.circle.fill")
                                .font(.title3)
                                .foregroundColor(.appAccent)
                        }
                    }
                    if canEdit {
                        Menu {
                            Button {
                                showAddSong = true
                            } label: {
                                Label("Add Song", systemImage: "music.note.badge.plus")
                            }
                            Button {
                                showManageTeam = true
                            } label: {
                                Label("Manage Team", systemImage: "person.badge.plus")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.appPrimary)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSong) {
            AddSongToSetlistView(setlistId: setlist.id, vm: vm)
        }
        .sheet(isPresented: $showManageTeam) {
            ManageTeamView(setlist: setlist, assignmentVM: assignmentVM)
                .environmentObject(bandVM)
        }
        .task {
            await vm.loadSetlistSongs(setlistId: setlist.id)
            await assignmentVM.loadAssignments(setlistId: setlist.id)
            // Load just this user's RSVP for this single service so the
            // pre-selected status is shown immediately on push navigation.
            if let bandId = bandVM.currentBand?.id {
                await vm.loadMyRSVPs(bandId: bandId)
            }
        }
    }

    // MARK: - Songs Tab

    private var songsTab: some View {
        List {
            serviceHeaderSection

            Section {
                if vm.setlistSongs.isEmpty {
                    emptySongsPlaceholder
                } else {
                    ForEach(vm.setlistSongs) { item in
                        ServiceSongRow(item: item)
                    }
                    .onMove { source, destination in
                        guard canEdit else { return }
                        vm.moveSetlistSong(setlistId: setlist.id, from: source, to: destination)
                    }
                    .onDelete { indexSet in
                        guard canEdit else { return }
                        Task {
                            for idx in indexSet {
                                let item = vm.setlistSongs[idx]
                                if let songId = item.songId {
                                    await vm.removeSongFromSetlist(setlistId: setlist.id, songId: songId)
                                }
                            }
                        }
                    }
                }
            } header: {
                if !vm.setlistSongs.isEmpty {
                    HStack(spacing: 4) {
                        Text("\(vm.setlistSongs.count) songs")
                        if !totalDurationString.isEmpty {
                            Text("·")
                            Text(totalDurationString)
                        }
                    }
                    .font(.appCaption)
                    .foregroundColor(.appSecondary)
                    .textCase(nil)
                }
            }

            if !vm.setlistSongs.isEmpty {
                Section {
                    Button {
                        PracticeManager.shared.startSession(songs: vm.setlistSongs)
                    } label: {
                        Label("Start Practice Session", systemImage: "metronome.fill")
                            .font(.appHeadline)
                            .foregroundColor(.appAccent)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .toolbar { if canEdit { EditButton() } }
    }

    // MARK: - Team Tab

    private var teamTab: some View {
        List {
            if assignmentVM.assignments.isEmpty {
                Section {
                    emptyTeamPlaceholder
                }
            } else {
                Section("Scheduled Team") {
                    ForEach(assignmentVM.assignments) { assignment in
                        AssignmentRow(assignment: assignment)
                    }
                    .onDelete { indexSet in
                        guard canEdit else { return }
                        Task {
                            for idx in indexSet {
                                await assignmentVM.removeAssignment(assignmentVM.assignments[idx])
                            }
                        }
                    }
                }
            }

            if canEdit {
                Section {
                    Button {
                        showManageTeam = true
                    } label: {
                        Label("Add Team Member", systemImage: "person.badge.plus")
                            .foregroundColor(.appAccent)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Sub-views

    /// RSVP buttons for the service. Same UX as the rehearsal RSVP row.
    @ViewBuilder
    private var rsvpRow: some View {
        let myStatus = vm.rsvpStatus(for: setlist.id)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.appAccent)
                Text("will_you_attend".localized)
                    .font(.appCaption)
                    .foregroundColor(.appSecondary)
            }
            HStack(spacing: 8) {
                RSVPButton(
                    title: "rsvp_going".localized,
                    icon: "checkmark",
                    color: .statusGoing,
                    isSelected: myStatus == "going"
                ) { Task { await vm.rsvp(setlistId: setlist.id, status: "going") } }
                RSVPButton(
                    title: "rsvp_maybe".localized,
                    icon: "questionmark",
                    color: .statusMaybe,
                    isSelected: myStatus == "maybe"
                ) { Task { await vm.rsvp(setlistId: setlist.id, status: "maybe") } }
                RSVPButton(
                    title: "rsvp_no".localized,
                    icon: "xmark",
                    color: .statusNo,
                    isSelected: myStatus == "not_going"
                ) { Task { await vm.rsvp(setlistId: setlist.id, status: "not_going") } }
                Spacer(minLength: 0)
            }
        }
    }

    private var serviceHeaderSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 16) {
                    if let date = setlist.formattedDate {
                        HStack(spacing: 6) {
                            Label(date, systemImage: "calendar")
                                .font(.appCaption)
                                .foregroundColor(.appSecondary)
                            if let time = setlist.formattedTime {
                                Text("·")
                                    .foregroundColor(.appDivider)
                                Text(time)
                                    .font(.appCaption)
                                    .foregroundColor(.appSecondary)
                            }
                        }
                    }
                    if setlist.serviceType != nil {
                        ServiceTypeBadge(setlist: setlist)
                    }
                }
                if let location = setlist.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.circle.fill")
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)
                }
                if let theme = setlist.theme, !theme.isEmpty {
                    Label(theme, systemImage: "sparkles")
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)
                        .italic()
                }
                if let notes = setlist.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)
                        .padding(.top, 2)
                }

                if setlist.parsedDate != nil {
                    Button {
                        Task { await addToCalendar() }
                    } label: {
                        Label(
                            calendarAdded ? "Added to Calendar" : "Add to Calendar",
                            systemImage: calendarAdded ? "checkmark.circle.fill" : "calendar.badge.plus"
                        )
                        .font(.appCaption)
                        .fontWeight(.semibold)
                        .foregroundColor(calendarAdded ? .statusGoing : .appAccent)
                    }
                    .disabled(calendarAdded)
                    .padding(.top, 4)
                }

                Divider().padding(.vertical, 6)
                rsvpRow
            }
        }
        .listRowBackground(Color.appSurface)
        .alert("Could not add to calendar. Please allow calendar access in Settings.", isPresented: $showCalendarError) {
            Button("OK", role: .cancel) {}
        }
    }

    private func addToCalendar() async {
        guard let startDate = setlist.scheduledDate else { return }
        let success = await CalendarService.addEvent(
            title: setlist.name,
            startDate: startDate,
            location: setlist.location,
            notes: [setlist.serviceType != nil ? setlist.serviceTypeDisplay : nil, setlist.theme].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
        )
        if success {
            calendarAdded = true
        } else {
            showCalendarError = true
        }
    }

    private var emptySongsPlaceholder: some View {
        HStack {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 36))
                    .foregroundColor(.appDivider)
                Text("No songs yet")
                    .font(.appBody)
                    .foregroundColor(.appSecondary)
                if canEdit {
                    Button { showAddSong = true } label: {
                        Text("Add First Song")
                            .font(.appCaption)
                            .foregroundColor(.appAccent)
                    }
                }
            }
            .padding(.vertical, 28)
            Spacer()
        }
        .listRowBackground(Color.appSurface)
    }

    private var emptyTeamPlaceholder: some View {
        HStack {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: "person.3")
                    .font(.system(size: 36))
                    .foregroundColor(.appDivider)
                Text("No team assigned yet")
                    .font(.appBody)
                    .foregroundColor(.appSecondary)
                if canEdit {
                    Button { showManageTeam = true } label: {
                        Text("Assign Team")
                            .font(.appCaption)
                            .foregroundColor(.appAccent)
                    }
                }
            }
            .padding(.vertical, 28)
            Spacer()
        }
        .listRowBackground(Color.appSurface)
    }
}

// MARK: - Service Song Row

struct ServiceSongRow: View {
    let item: SetlistSong

    var body: some View {
        NavigationLink {
            if let song = item.songs {
                SongDetailView(song: song)
            }
        } label: {
            HStack(spacing: 12) {
                // Position badge
                Text("\(item.position)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.appAccent)
                    .frame(width: 26, height: 26)
                    .background(Color.appAccent.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.songs?.title ?? "Unknown")
                        .font(.appHeadline)
                        .foregroundColor(.appPrimary)

                    HStack(spacing: 8) {
                        if let artist = item.songs?.artist {
                            Text(artist)
                                .font(.appCaption)
                                .foregroundColor(.appSecondary)
                        }
                        if let key = item.displayKey {
                            KeyBadge(key: key)
                        }
                        if let bpm = item.songs?.tempoBpm {
                            Text("\(bpm) BPM")
                                .font(.appCaption)
                                .foregroundColor(.appSecondary)
                        }
                        if let dur = item.songs?.formattedDuration {
                            Text(dur)
                                .font(.appCaption)
                                .foregroundColor(.appSecondary)
                        }
                    }
                }
            }
            .padding(.vertical, 3)
        }
        .listRowBackground(Color.appSurface)
    }
}

// MARK: - Assignment Row

struct AssignmentRow: View {
    let assignment: ServiceAssignment

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.appAccent.opacity(0.15))
                    .frame(width: 40, height: 40)
                Text(String(assignment.member?.fullName.prefix(1) ?? "?").uppercased())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appAccent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(assignment.member?.fullName ?? "Team Member")
                    .font(.appHeadline)
                    .foregroundColor(.appPrimary)
                Text(assignment.roleDisplay)
                    .font(.appCaption)
                    .foregroundColor(.appSecondary)
            }

            Spacer()

            statusBadge
        }
        .padding(.vertical, 3)
        .listRowBackground(Color.appSurface)
    }

    @ViewBuilder
    private var statusBadge: some View {
        let (color, label) = statusInfo
        Text(label)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private var statusInfo: (Color, String) {
        switch assignment.status {
        case "confirmed": return (.statusGoing, "Confirmed")
        case "declined":  return (.statusNo,   "Declined")
        default:          return (.statusMaybe, "Pending")
        }
    }
}
