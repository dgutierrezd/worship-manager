import SwiftUI

// MARK: - Band Home / Dashboard (OnStage-inspired)

struct BandHomeView: View {
    @EnvironmentObject var bandVM: BandViewModel
    @StateObject private var rehearsalVM = RehearsalsViewModel()
    @StateObject private var setlistVM = SetlistViewModel()
    @StateObject private var songsVM = SongsViewModel()

    var upcomingServices: [Setlist] {
        setlistVM.setlists.filter { $0.isUpcoming }.prefix(4).map { $0 }
    }

    private var isInitialLoading: Bool {
        (setlistVM.isLoading || songsVM.isLoading || rehearsalVM.isLoading)
        && setlistVM.setlists.isEmpty && songsVM.songs.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    bandHeader
                    if isInitialLoading {
                        skeletonDashboard
                    } else {
                        quickStats
                        nextServiceSection
                        upcomingServicesSection
                        recentSongsSection
                    }
                    Spacer(minLength: 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.appPrimary)
                    }
                }
            }
            .refreshable { await loadAll() }
            .task { await loadAll() }
        }
        .background(Color.appBackground)
    }

    // MARK: - Band Header

    private var bandHeader: some View {
        VStack(spacing: 10) {
            if let band = bandVM.currentBand {
                BandAvatarView(band: band, size: 72)

                Text(band.name)
                    .font(.appTitle)
                    .foregroundColor(.appPrimary)

                HStack(spacing: 6) {
                    if let church = band.church {
                        Text(church)
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)
                        Text("·")
                            .foregroundColor(.appDivider)
                    }
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.appSecondary)
                    Text("\(band.memberCount ?? 0) members")
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)
                }

                if let role = band.myRole {
                    Text(role == "leader" ? "Worship Leader" : "Member")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(role == "leader" ? .appAccent : .appSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(role == "leader" ? Color.appAccent.opacity(0.12) : Color.appDivider.opacity(0.5))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
    }

    // MARK: - Quick Stats Bar

    private var quickStats: some View {
        HStack(spacing: 0) {
            statItem(value: "\(setlistVM.setlists.filter { $0.isUpcoming }.count)", label: "Services")
            Divider().frame(height: 30).opacity(0.5)
            statItem(value: "\(songsVM.songs.count)", label: "Songs")
            Divider().frame(height: 30).opacity(0.5)
            statItem(value: "\(rehearsalVM.upcomingRehearsals.count)", label: "Rehearsals")
        }
        .padding(.vertical, 16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.appPrimary)
            Text(label)
                .font(.appCaption)
                .foregroundColor(.appSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Next Service

    @ViewBuilder
    private var nextServiceSection: some View {
        if let next = upcomingServices.first {
            SectionHeader(title: "Next Service")
            NavigationLink {
                ServiceDetailView(setlist: next)
                    .environmentObject(bandVM)
            } label: {
                NextServiceCard(setlist: next)
                    .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 24)
        } else if let next = rehearsalVM.nextRehearsal {
            SectionHeader(title: "next_rehearsal".localized)
            NextRehearsalCard(rehearsal: next, rehearsalVM: rehearsalVM)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        }
    }

    // MARK: - Upcoming Services

    @ViewBuilder
    private var upcomingServicesSection: some View {
        if upcomingServices.count > 1 {
            SectionHeader(title: "Upcoming Services", trailing: "See All")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(upcomingServices.dropFirst()) { setlist in
                        NavigationLink {
                            ServiceDetailView(setlist: setlist)
                                .environmentObject(bandVM)
                        } label: {
                            ServiceCard(setlist: setlist)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - Recent Songs

    @ViewBuilder
    private var recentSongsSection: some View {
        if !songsVM.songs.isEmpty {
            SectionHeader(title: "songs".localized, trailing: "See All")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(songsVM.songs.prefix(8)) { song in
                        NavigationLink {
                            SongDetailView(song: song)
                        } label: {
                            SongChip(song: song)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - Skeleton Dashboard

    private var skeletonDashboard: some View {
        VStack(spacing: 0) {
            // Stats bar skeleton
            HStack(spacing: 0) {
                ForEach(0..<3) { idx in
                    VStack(spacing: 6) {
                        SkeletonBlock(width: 36, height: 22, cornerRadius: 6)
                        SkeletonBlock(width: 56, height: 10)
                    }
                    .frame(maxWidth: .infinity)
                    if idx < 2 {
                        Divider().frame(height: 30).opacity(0.5)
                    }
                }
            }
            .padding(.vertical, 16)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)

            // Next service skeleton card
            VStack(alignment: .leading, spacing: 14) {
                SkeletonBlock(width: 120, height: 12)
                SkeletonBlock(height: 110, cornerRadius: 14)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)

            // Horizontal scroll skeleton
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SkeletonBlock(width: 100, height: 12)
                    Spacer()
                    SkeletonBlock(width: 50, height: 10)
                }
                .padding(.horizontal, 16)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(0..<5, id: \.self) { _ in
                            SkeletonBlock(width: 130, height: 76, cornerRadius: 12)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 24)

            // Songs skeleton
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SkeletonBlock(width: 80, height: 12)
                    Spacer()
                    SkeletonBlock(width: 50, height: 10)
                }
                .padding(.horizontal, 16)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(0..<6, id: \.self) { _ in
                            SkeletonBlock(width: 90, height: 90, cornerRadius: 12)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    // MARK: - Data Loading

    private func loadAll() async {
        guard let bandId = bandVM.currentBand?.id else { return }
        await bandVM.refreshCurrentBand()
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await rehearsalVM.loadRehearsals(bandId: bandId) }
            group.addTask { await setlistVM.loadSetlists(bandId: bandId) }
            group.addTask { await songsVM.loadSongs(bandId: bandId) }
        }
    }
}

// MARK: - Next Service Card (featured, large)

struct NextServiceCard: View {
    let setlist: Setlist

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(setlist.name)
                        .font(.appTitle)
                        .foregroundColor(.appPrimary)
                        .lineLimit(2)

                    if let date = setlist.formattedDate {
                        Label(date, systemImage: "calendar")
                            .font(.appBody)
                            .foregroundColor(.appSecondary)
                    }
                }

                Spacer()

                if setlist.serviceType != nil {
                    ServiceTypeBadge(setlist: setlist)
                }
            }

            HStack(spacing: 12) {
                if let location = setlist.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.circle")
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)
                }
                if let theme = setlist.theme, !theme.isEmpty {
                    Label(theme, systemImage: "sparkles")
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)
                }
            }

            Divider().opacity(0.5)

            HStack {
                Label("View Service Plan", systemImage: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.appAccent)
                Spacer()
            }
        }
        .padding(18)
        .cardStyle()
    }
}

// MARK: - Service Card (horizontal scroll)

struct ServiceCard: View {
    let setlist: Setlist

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if setlist.serviceType != nil {
                ServiceTypeBadge(setlist: setlist)
            }

            Text(setlist.name)
                .font(.appHeadline)
                .foregroundColor(.appPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            if let date = setlist.formattedDate {
                Text(date)
                    .font(.appCaption)
                    .foregroundColor(.appSecondary)
            }
        }
        .frame(width: 160, alignment: .leading)
        .padding(14)
        .cardStyle()
    }
}

// MARK: - Legacy sub-views kept for compatibility

struct NextRehearsalCard: View {
    let rehearsal: Rehearsal
    @ObservedObject var rehearsalVM: RehearsalsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.appAccent)
                Text("\(rehearsal.formattedDate) · \(rehearsal.formattedTime)")
                    .font(.appHeadline)
                    .foregroundColor(.appPrimary)
            }

            if let location = rehearsal.location {
                Text(location)
                    .font(.appBody)
                    .foregroundColor(.appSecondary)
            }

            if let setlistName = rehearsal.setlists?.name {
                Text("Setlist: \(setlistName)")
                    .font(.appCaption)
                    .foregroundColor(.appSecondary)
            }

            HStack(spacing: 10) {
                RSVPButton(title: "rsvp_going".localized, icon: "checkmark", color: .statusGoing,
                           isSelected: rehearsalVM.myRSVP == "going") {
                    Task { await rehearsalVM.rsvp(rehearsalId: rehearsal.id, status: "going") }
                }
                RSVPButton(title: "rsvp_maybe".localized, icon: "questionmark", color: .statusMaybe,
                           isSelected: rehearsalVM.myRSVP == "maybe") {
                    Task { await rehearsalVM.rsvp(rehearsalId: rehearsal.id, status: "maybe") }
                }
                RSVPButton(title: "rsvp_no".localized, icon: "xmark", color: .statusNo,
                           isSelected: rehearsalVM.myRSVP == "not_going") {
                    Task { await rehearsalVM.rsvp(rehearsalId: rehearsal.id, status: "not_going") }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }
}

struct SetlistCard: View {
    let setlist: Setlist

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(setlist.name)
                .font(.appHeadline)
                .foregroundColor(.appPrimary)
                .lineLimit(1)
            if let date = setlist.formattedDate {
                Text(date)
                    .font(.appCaption)
                    .foregroundColor(.appSecondary)
            }
        }
        .frame(width: 160, alignment: .leading)
        .padding(16)
        .cardStyle()
    }
}

struct SongChip: View {
    let song: Song

    var body: some View {
        HStack(spacing: 8) {
            Text(song.title)
                .font(.appCaption)
                .foregroundColor(.appPrimary)
                .lineLimit(1)
            if let key = song.defaultKey {
                KeyBadge(key: key)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.appSurface)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.appDivider, lineWidth: 1))
    }
}
