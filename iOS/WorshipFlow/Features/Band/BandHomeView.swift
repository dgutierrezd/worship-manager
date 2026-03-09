import SwiftUI

struct BandHomeView: View {
    @EnvironmentObject var bandVM: BandViewModel
    @StateObject private var rehearsalVM = RehearsalsViewModel()
    @StateObject private var setlistVM = SetlistViewModel()
    @StateObject private var songsVM = SongsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Band Header
                    bandHeader

                    // Next Rehearsal
                    if let next = rehearsalVM.nextRehearsal {
                        SectionHeader(title: "next_rehearsal".localized)
                        NextRehearsalCard(rehearsal: next, rehearsalVM: rehearsalVM)
                            .padding(.horizontal)
                    }

                    // Upcoming Setlists
                    if !setlistVM.setlists.isEmpty {
                        SectionHeader(
                            title: "setlists".localized,
                            trailing: "See All"
                        )
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(setlistVM.setlists.prefix(5)) { setlist in
                                    NavigationLink {
                                        SetlistDetailView(setlist: setlist)
                                    } label: {
                                        SetlistCard(setlist: setlist)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Recent Songs
                    if !songsVM.songs.isEmpty {
                        SectionHeader(
                            title: "songs".localized,
                            trailing: "See All"
                        )
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(songsVM.songs.prefix(6)) { song in
                                    NavigationLink {
                                        SongDetailView(song: song)
                                    } label: {
                                        SongChip(song: song)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 32)
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
            .refreshable {
                await loadAll()
            }
            .task {
                await loadAll()
            }
        }
        .background(Color.appBackground)
    }

    private var bandHeader: some View {
        VStack(spacing: 8) {
            if let band = bandVM.currentBand {
                BandAvatarView(band: band, size: 64)

                Text(band.name)
                    .font(.appTitle)
                    .foregroundColor(.appPrimary)

                if let church = band.church {
                    Text("\(church) · \(band.memberCount ?? 0) members")
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)
                } else {
                    Text("\(band.memberCount ?? 0) members")
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)
                }
            }
        }
        .padding(.vertical, 24)
    }

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

// MARK: - Subviews

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
                RSVPButton(
                    title: "rsvp_going".localized,
                    icon: "checkmark",
                    color: .statusGoing,
                    isSelected: rehearsalVM.myRSVP == "going"
                ) {
                    Task { await rehearsalVM.rsvp(rehearsalId: rehearsal.id, status: "going") }
                }

                RSVPButton(
                    title: "rsvp_maybe".localized,
                    icon: "questionmark",
                    color: .statusMaybe,
                    isSelected: rehearsalVM.myRSVP == "maybe"
                ) {
                    Task { await rehearsalVM.rsvp(rehearsalId: rehearsal.id, status: "maybe") }
                }

                RSVPButton(
                    title: "rsvp_no".localized,
                    icon: "xmark",
                    color: .statusNo,
                    isSelected: rehearsalVM.myRSVP == "not_going"
                ) {
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
