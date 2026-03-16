import SwiftUI

// MARK: - Members / Team View (OnStage-inspired)

struct MembersView: View {
    @EnvironmentObject var bandVM: BandViewModel
    @State private var members: [Member] = []
    @State private var isLoading = false
    @State private var searchText = ""

    var filteredMembers: [Member] {
        guard !searchText.isEmpty else { return members }
        return members.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            ($0.instrument?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var leaders: [Member] { filteredMembers.filter { $0.isLeader } }
    var regularMembers: [Member] { filteredMembers.filter { !$0.isLeader } }

    var body: some View {
        NavigationStack {
            List {
                // Leaders section
                if !leaders.isEmpty {
                    Section("Leadership") {
                        ForEach(leaders) { member in
                            NavigationLink {
                                MemberProfileView(member: member, bandId: bandVM.currentBand?.id ?? "")
                            } label: {
                                MemberRow(member: member)
                            }
                            .listRowBackground(Color.appSurface)
                        }
                    }
                }

                // Members section
                if !regularMembers.isEmpty {
                    Section("Members (\(regularMembers.count))") {
                        ForEach(regularMembers) { member in
                            NavigationLink {
                                MemberProfileView(member: member, bandId: bandVM.currentBand?.id ?? "")
                            } label: {
                                MemberRow(member: member)
                            }
                            .listRowBackground(Color.appSurface)
                        }
                    }
                }

                // Invite section
                Section {
                    InviteCodeSection(band: bandVM.currentBand)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .searchable(text: $searchText, prompt: "Search team members…")
            .navigationTitle("Team")
            .refreshable { await loadMembers() }
            .task { await loadMembers() }
            .overlay {
                if isLoading && members.isEmpty {
                    ProgressView()
                }
            }
        }
        .background(Color.appBackground)
    }

    private func loadMembers() async {
        guard let bandId = bandVM.currentBand?.id else { return }
        isLoading = true
        do {
            members = try await BandService.getMembers(bandId: bandId)
        } catch {
            print("Failed to load members: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Member Row (improved)

struct MemberRow: View {
    let member: Member

    var body: some View {
        HStack(spacing: 12) {
            // Avatar with colored background
            ZStack {
                Circle()
                    .fill(avatarColor(for: member.fullName).opacity(0.18))
                    .frame(width: 46, height: 46)
                Text(String(member.fullName.prefix(1)).uppercased())
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(avatarColor(for: member.fullName))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(member.fullName)
                        .font(.appHeadline)
                        .foregroundColor(.appPrimary)

                    if member.isLeader {
                        Text("Leader")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.appAccent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appAccent.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                if let instrument = member.instrument {
                    HStack(spacing: 5) {
                        Image(systemName: member.instrumentIcon)
                            .font(.system(size: 11))
                            .foregroundColor(.appSecondary)
                        Text(instrument)
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    /// Generate a consistent color for each name
    private func avatarColor(for name: String) -> Color {
        let colors: [Color] = [.appAccent, .statusGoing, Color(hex: "#5B6AF0"),
                                Color(hex: "#E05C97"), Color(hex: "#3AA0C4")]
        let idx = abs(name.hashValue) % colors.count
        return colors[idx]
    }
}

// MARK: - Invite Code Section (improved)

struct InviteCodeSection: View {
    let band: Band?
    @State private var copied = false

    var body: some View {
        VStack(spacing: 14) {
            Label("Invite Code", systemImage: "person.badge.plus")
                .font(.appCaption)
                .foregroundColor(.appSecondary)

            Text(band?.inviteCode ?? "------")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.appPrimary)
                .tracking(8)

            HStack(spacing: 16) {
                Button {
                    UIPasteboard.general.string = band?.inviteCode
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { copied = false }
                    }
                } label: {
                    Label(copied ? "Copied!" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.appCaption)
                        .foregroundColor(copied ? .statusGoing : .appAccent)
                }

                if let band {
                    ShareLink(item: "Join \"\(band.name)\" on Worship Manager! Code: \(band.inviteCode)") {
                        Label("share_invite".localized, systemImage: "square.and.arrow.up")
                            .font(.appCaption)
                            .foregroundColor(.appAccent)
                    }
                }
            }

            Text("Anyone with this code can join your team")
                .font(.appCaption)
                .foregroundColor(.appSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .listRowBackground(Color.appSurface)
    }
}
