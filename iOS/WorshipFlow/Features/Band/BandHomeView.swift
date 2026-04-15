import SwiftUI

// MARK: - Band Home / Dashboard

struct BandHomeView: View {
    @EnvironmentObject var bandVM: BandViewModel
    @StateObject private var rehearsalVM = RehearsalsViewModel()
    @StateObject private var setlistVM = SetlistViewModel()
    @StateObject private var songsVM = SongsViewModel()
    @StateObject private var inboxVM = NotificationInboxViewModel()
    @ObservedObject private var deepLink = DeepLinkRouter.shared

    /// Nav-stack path — allows programmatic push from push-notification taps
    /// and inbox taps via `DeepLinkRouter`.
    @State private var path = NavigationPath()

    /// Typed deep-link destinations pushed onto `path`. Carries just the
    /// id so Swift can synthesize Hashable trivially; the concrete model
    /// is resolved from the VM's loaded list (or `routeCache` for items
    /// fetched on-demand from a push tap).
    enum HomeRoute: Hashable {
        case service(id: String)
        case rehearsal(id: String)
    }

    @State private var showInbox = false
    @State private var deepLinkError: String?
    @State private var routeCacheSetlists: [String: Setlist] = [:]
    @State private var routeCacheRehearsals: [String: Rehearsal] = [:]

    var upcomingServices: [Setlist] {
        setlistVM.setlists.filter { $0.isUpcoming }.prefix(4).map { $0 }
    }

    private var isInitialLoading: Bool {
        (setlistVM.isLoading || songsVM.isLoading || rehearsalVM.isLoading)
        && setlistVM.setlists.isEmpty && songsVM.songs.isEmpty
    }

    var body: some View {
        NavigationStack(path: $path) {
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showInbox = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.appPrimary)
                                .padding(8)

                            if inboxVM.unreadCount > 0 {
                                Text(inboxVM.unreadCount > 99 ? "99+" : "\(inboxVM.unreadCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    .accessibilityLabel(Text("notifications".localized))
                }
            }
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .service(let id):
                    if let setlist = setlistVM.setlists.first(where: { $0.id == id })
                        ?? routeCacheSetlists[id] {
                        ServiceDetailView(setlist: setlist)
                            .environmentObject(bandVM)
                    } else {
                        MissingItemView(message: "This service is no longer available.")
                    }
                case .rehearsal(let id):
                    if let rehearsal = rehearsalVM.rehearsals.first(where: { $0.id == id })
                        ?? routeCacheRehearsals[id] {
                        RehearsalDetailView(rehearsal: rehearsal, vm: rehearsalVM)
                    } else {
                        MissingItemView(message: "This rehearsal is no longer available.")
                    }
                }
            }
            .sheet(isPresented: $showInbox, onDismiss: {
                Task { await inboxVM.refreshUnreadCount() }
            }) {
                NotificationInboxView()
            }
            .refreshable { await loadAll() }
            .task { await loadAll() }
            .task { await inboxVM.refreshUnreadCount() }
            .onChange(of: deepLink.pendingRoute) { _, newValue in
                guard let newValue else { return }
                Task { await consumeDeepLink(newValue) }
            }
            .alert("Could not open", isPresented: .init(
                get: { deepLinkError != nil },
                set: { if !$0 { deepLinkError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deepLinkError ?? "")
            }
        }
        .background(Color.appBackground)
    }

    // MARK: - Deep link handling

    /// Resolves a `DeepLinkRoute` (service / rehearsal id from a push or
    /// inbox tap) to a concrete model and pushes it onto the nav stack.
    /// Tries the locally cached list first for instant navigation; falls
    /// back to a single-item REST fetch if not present (e.g. first-launch
    /// from a push tap).
    private func consumeDeepLink(_ route: DeepLinkRoute) async {
        defer { deepLink.clear() }

        switch route {
        case .service(let id):
            if setlistVM.setlists.contains(where: { $0.id == id }) {
                path.append(HomeRoute.service(id: id))
                return
            }
            do {
                let fetched = try await SetlistService.getSetlist(id: id)
                routeCacheSetlists[fetched.id] = fetched
                path.append(HomeRoute.service(id: fetched.id))
            } catch {
                deepLinkError = "That service is no longer available."
            }

        case .rehearsal(let id):
            if rehearsalVM.rehearsals.contains(where: { $0.id == id }) {
                path.append(HomeRoute.rehearsal(id: id))
                return
            }
            do {
                let fetched = try await RehearsalService.getRehearsal(id: id)
                routeCacheRehearsals[fetched.id] = fetched
                path.append(HomeRoute.rehearsal(id: fetched.id))
            } catch {
                deepLinkError = "That rehearsal is no longer available."
            }
        }
    }

    // MARK: - Missing item fallback

    /// Tiny placeholder shown if the deep-link target can't be resolved
    /// (item was deleted, or the fetch failed after the route was pushed).
    private struct MissingItemView: View {
        let message: String
        var body: some View {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.appSecondary)
                Text(message)
                    .font(.appBody)
                    .foregroundColor(.appSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
        }
    }

    // MARK: - Band Header (Hero)

    private var bandHeader: some View {
        ZStack(alignment: .bottom) {
            // Soft blue aurora background
            AppGradients.hero
                .frame(height: 260)
                .ignoresSafeArea(edges: .top)

            // Brand glow behind avatar
            AppGradients.brandGlow
                .frame(width: 240, height: 240)
                .offset(y: -28)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)

            VStack(spacing: 12) {
                if let band = bandVM.currentBand {
                    // Avatar with subtle brand ring
                    BandAvatarView(
                        band: band,
                        size: 84,
                        showLeaderRing: false
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color.appAccent.opacity(0.28), lineWidth: 1)
                    )
                    .shadow(color: Color.appAccent.opacity(0.25), radius: 16, x: 0, y: 8)

                    Text(band.name)
                        .font(.appLargeTitle)
                        .foregroundColor(.appPrimary)
                        .tracking(-0.3)

                    HStack(spacing: 8) {
                        if let church = band.church {
                            Text(church)
                                .font(.appCaption)
                                .foregroundColor(.appSecondary)
                            Circle()
                                .fill(Color.appDivider)
                                .frame(width: 3, height: 3)
                        }
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.appAccent)
                        Text("\(band.memberCount ?? 0) \("members".localized)")
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.appSurface.opacity(0.70))
                            .overlay(Capsule().stroke(Color.appDivider, lineWidth: 0.5))
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                ZStack {
                    // Soft color-tinted halo
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accentColor.opacity(0.14))
                        .frame(width: 48, height: 48)

                    // Vibrant gradient pill
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.78)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                        .shadow(color: accentColor.opacity(0.45), radius: 10, x: 0, y: 6)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.appSecondary.opacity(0.45))
                    .padding(6)
                    .background(Circle().fill(Color.appDivider.opacity(0.5)))
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.appShadow, radius: 14, x: 0, y: 6)
        .shadow(color: Color.appShadow.opacity(0.5), radius: 2, x: 0, y: 1)
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
        .shadow(color: Color.appShadow, radius: 6, x: 0, y: 3)
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
