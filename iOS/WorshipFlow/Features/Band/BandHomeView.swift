import SwiftUI

// MARK: - Band Home / Dashboard

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
                            .padding(.top, -20)
                        quickAccessGrid
                        nextServiceSection
                        upcomingServicesSection
                        recentSongsSection
                    }
                    Spacer(minLength: 48)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await loadAll() }
            .task { await loadAll() }
        }
        .background(Color.appBackground)
    }

    // MARK: - Band Header (Hero)

    private var bandHeader: some View {
        ZStack(alignment: .bottom) {
            // Gold hero gradient background
            AppGradients.hero
                .frame(height: 240)
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 10) {
                if let band = bandVM.currentBand {
                    // Avatar with leader ring
                    BandAvatarView(
                        band: band,
                        size: 80,
                        showLeaderRing: band.myRole == "leader"
                    )
                    .shadow(color: Color.appAccent.opacity(0.20), radius: 12, x: 0, y: 4)

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
                        Text("\(band.memberCount ?? 0) \("members".localized)")
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)
                    }

                    if let role = band.myRole {
                        RoleBadge(role: role)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Quick Stats Bar

    private var quickStats: some View {
        HStack(spacing: 0) {
            statItem(
                value: "\(setlistVM.setlists.filter { $0.isUpcoming }.count)",
                label: "Services",
                icon: "music.note.list",
                color: .featureServices
            )
            statDivider
            statItem(
                value: "\(songsVM.songs.count)",
                label: "songs".localized,
                icon: "music.note",
                color: .featureSongs
            )
            statDivider
            statItem(
                value: "\(rehearsalVM.upcomingRehearsals.count)",
                label: "rehearsals".localized,
                icon: "calendar",
                color: .featureSchedule
            )
        }
        .padding(.vertical, 18)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.07), radius: 14, x: 0, y: 5)
        .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 1)
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
        .zIndex(1)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.appDivider)
            .frame(width: 1, height: 36)
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.appPrimary)
            Text(label)
                .font(.appSmall)
                .foregroundColor(.appSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Quick Access Grid

    private var quickAccessGrid: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Explore")
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                spacing: 14
            ) {
                NavigationLink { ServicesView().environmentObject(bandVM) } label: {
                    QuickAccessCard(
                        icon: "music.note.list",
                        title: "Services",
                        subtitle: upcomingServices.isEmpty
                            ? "No upcoming"
                            : "\(setlistVM.setlists.filter { $0.isUpcoming }.count) upcoming",
                        accentColor: .featureServices
                    )
                }
                .buttonStyle(CardPressButtonStyle())

                NavigationLink { SongLibraryView().environmentObject(bandVM) } label: {
                    QuickAccessCard(
                        icon: "music.note",
                        title: "songs".localized,
                        subtitle: songsVM.songs.isEmpty
                            ? "Add songs"
                            : "\(songsVM.songs.count) tracks",
                        accentColor: .featureSongs
                    )
                }
                .buttonStyle(CardPressButtonStyle())

                NavigationLink { RehearsalsView().environmentObject(bandVM) } label: {
                    QuickAccessCard(
                        icon: "calendar",
                        title: "Schedule",
                        subtitle: rehearsalVM.nextRehearsal.map { "Next: \($0.formattedDate)" }
                            ?? "No rehearsals",
                        accentColor: .featureSchedule
                    )
                }
                .buttonStyle(CardPressButtonStyle())

                NavigationLink { MembersView().environmentObject(bandVM) } label: {
                    QuickAccessCard(
                        icon: "person.3.fill",
                        title: "Team",
                        subtitle: "\(bandVM.currentBand?.memberCount ?? 0) members",
                        accentColor: .featureTeam
                    )
                }
                .buttonStyle(CardPressButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
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
                    .padding(.horizontal, 20)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 28)
        } else if let next = rehearsalVM.nextRehearsal {
            SectionHeader(title: "next_rehearsal".localized)
            NextRehearsalCard(rehearsal: next, rehearsalVM: rehearsalVM)
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
        }
    }

    // MARK: - Upcoming Services

    @ViewBuilder
    private var upcomingServicesSection: some View {
        if upcomingServices.count > 1 {
            SectionHeader(title: "Upcoming Services", trailing: "See All")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
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
                .padding(.horizontal, 20)
                .padding(.vertical, 2)
            }
            .padding(.bottom, 28)
        }
    }

    // MARK: - Recent Songs

    @ViewBuilder
    private var recentSongsSection: some View {
        if !songsVM.songs.isEmpty {
            SectionHeader(title: "songs".localized, trailing: "See All")
            FlowLayout(spacing: 10) {
                ForEach(songsVM.songs.prefix(10)) { song in
                    NavigationLink {
                        SongDetailView(song: song)
                    } label: {
                        SongChip(song: song)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Skeleton Dashboard

    private var skeletonDashboard: some View {
        VStack(spacing: 0) {
            // Stats bar skeleton
            HStack(spacing: 0) {
                ForEach(0..<3) { idx in
                    VStack(spacing: 6) {
                        SkeletonBlock(width: 20, height: 14, cornerRadius: 4)
                        SkeletonBlock(width: 36, height: 22, cornerRadius: 6)
                        SkeletonBlock(width: 56, height: 10)
                    }
                    .frame(maxWidth: .infinity)
                    if idx < 2 {
                        Rectangle()
                            .fill(Color.appDivider)
                            .frame(width: 1, height: 36)
                    }
                }
            }
            .padding(.vertical, 18)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
            .padding(.top, -20)
            .zIndex(1)

            // Next service skeleton card
            VStack(alignment: .leading, spacing: 14) {
                SkeletonBlock(width: 120, height: 12)
                SkeletonBlock(height: 120, cornerRadius: 18)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)

            // Horizontal scroll skeleton
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SkeletonBlock(width: 100, height: 12)
                    Spacer()
                    SkeletonBlock(width: 50, height: 10)
                }
                .padding(.horizontal, 20)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(0..<5, id: \.self) { _ in
                            SkeletonBlock(width: 140, height: 84, cornerRadius: 18)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 28)

            // Songs skeleton
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SkeletonBlock(width: 80, height: 12)
                    Spacer()
                    SkeletonBlock(width: 50, height: 10)
                }
                .padding(.horizontal, 20)
                FlowLayout(spacing: 10) {
                    ForEach([110, 80, 130, 90, 115, 75], id: \.self) { width in
                        SkeletonBlock(width: CGFloat(width), height: 36, cornerRadius: 18)
                    }
                }
                .padding(.horizontal, 20)
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

// MARK: - Role Badge

struct RoleBadge: View {
    let role: String

    var isLeader: Bool { role == "leader" }

    var body: some View {
        HStack(spacing: 5) {
            if isLeader {
                Image(systemName: "star.fill")
                    .font(.system(size: 9, weight: .bold))
            }
            Text(isLeader ? "Worship Leader" : "Member")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(isLeader ? .white : .appSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(
            Group {
                if isLeader {
                    AnyView(AppGradients.gold)
                } else {
                    AnyView(Color.appDivider.opacity(0.8))
                }
            }
        )
        .clipShape(Capsule())
        .shadow(color: isLeader ? Color.appAccent.opacity(0.30) : .clear, radius: 6, x: 0, y: 2)
    }
}

// MARK: - Quick Access Card
// No internal gesture — press animation is handled by CardPressButtonStyle
// applied to the NavigationLink, so navigation always fires correctly.

struct QuickAccessCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: accentColor.opacity(0.30), radius: 6, x: 0, y: 3)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.appSecondary.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.appHeadline)
                    .foregroundColor(.appPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.appSmall)
                    .foregroundColor(.appSecondary)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Card Press Button Style
// Use this on NavigationLink / Button instead of .buttonStyle(.plain).
// Delivers a spring scale-down on press without ever stealing the tap from navigation.

struct CardPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7),
                       value: configuration.isPressed)
    }
}

// MARK: - Song Chip

struct SongChip: View {
    let song: Song

    var body: some View {
        HStack(spacing: 7) {
            if let key = song.defaultKey {
                KeyBadge(key: key)
            }
            Text(song.title)
                .font(.appCaption)
                .fontWeight(.medium)
                .foregroundColor(.appPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Color.appSurface)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.appDivider, lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Next Service Card (featured, large)

struct NextServiceCard: View {
    let setlist: Setlist

    var body: some View {
        HStack(spacing: 0) {
            // Gold accent stripe
            RoundedRectangle(cornerRadius: 3)
                .fill(AppGradients.gold)
                .frame(width: 4)
                .padding(.vertical, 18)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
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

                if setlist.location != nil || setlist.theme != nil {
                    HStack(spacing: 12) {
                        if let location = setlist.location, !location.isEmpty {
                            Label(location, systemImage: "mappin.circle.fill")
                                .font(.appCaption)
                                .foregroundColor(.appSecondary)
                        }
                        if let theme = setlist.theme, !theme.isEmpty {
                            Label(theme, systemImage: "sparkles")
                                .font(.appCaption)
                                .foregroundColor(.appSecondary)
                        }
                    }
                }

                Divider().opacity(0.4)

                HStack(spacing: 5) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.appAccent)
                    Text("View Service Plan")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.appAccent)
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.appAccent.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.appAccent.opacity(0.10), radius: 12, x: 0, y: 4)
        .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
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
                Label(date, systemImage: "calendar")
                    .font(.appSmall)
                    .foregroundColor(.appSecondary)
            }
        }
        .frame(width: 170, alignment: .leading)
        .padding(16)
        .cardStyle()
    }
}

// MARK: - Next Rehearsal Card

struct NextRehearsalCard: View {
    let rehearsal: Rehearsal
    @ObservedObject var rehearsalVM: RehearsalsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.featureSchedule.opacity(0.14))
                        .frame(width: 40, height: 40)
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.featureSchedule)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(rehearsal.formattedDate) · \(rehearsal.formattedTime)")
                        .font(.appHeadline)
                        .foregroundColor(.appPrimary)
                    if let location = rehearsal.location {
                        Text(location)
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)
                    }
                }
            }

            if let setlistName = rehearsal.setlists?.name {
                HStack(spacing: 6) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 12))
                        .foregroundColor(.appAccent)
                    Text(setlistName)
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)
                }
            }

            Divider().opacity(0.4)

            HStack(spacing: 10) {
                RSVPButton(title: "rsvp_going".localized, icon: "checkmark", color: .statusGoing,
                           isSelected: rehearsalVM.rsvpStatus(for: rehearsal.id) == "going") {
                    Task { await rehearsalVM.rsvp(rehearsalId: rehearsal.id, status: "going") }
                }
                RSVPButton(title: "rsvp_maybe".localized, icon: "questionmark", color: .statusMaybe,
                           isSelected: rehearsalVM.rsvpStatus(for: rehearsal.id) == "maybe") {
                    Task { await rehearsalVM.rsvp(rehearsalId: rehearsal.id, status: "maybe") }
                }
                RSVPButton(title: "rsvp_no".localized, icon: "xmark", color: .statusNo,
                           isSelected: rehearsalVM.rsvpStatus(for: rehearsal.id) == "not_going") {
                    Task { await rehearsalVM.rsvp(rehearsalId: rehearsal.id, status: "not_going") }
                }
            }
        }
        .padding(18)
        .featuredCardStyle()
    }
}

// MARK: - Legacy

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
