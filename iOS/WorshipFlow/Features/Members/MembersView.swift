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

    var body: some View {
        NavigationStack {
            List {
                // All members in a single, equal section
                if !filteredMembers.isEmpty {
                    Section("Members (\(filteredMembers.count))") {
                        ForEach(filteredMembers) { member in
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
                    List {
                        Section {
                            SkeletonList(count: 3) { SkeletonMemberRow() }
                                .listRowBackground(Color.appSurface)
                        }
                        Section {
                            SkeletonList(count: 5) { SkeletonMemberRow() }
                                .listRowBackground(Color.appSurface)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .allowsHitTesting(false)
                    .background(Color.appBackground)
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
        HStack(spacing: 14) {
            // Avatar with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [avatarColor(for: member.fullName),
                                     avatarColor(for: member.fullName).opacity(0.70)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)
                    .shadow(color: avatarColor(for: member.fullName).opacity(0.20), radius: 5, x: 0, y: 2)
                Text(String(member.fullName.prefix(1)).uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(member.fullName)
                    .font(.appHeadline)
                    .foregroundColor(.appPrimary)
                    .lineLimit(1)

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
        .padding(.vertical, 5)
    }

    /// Generate a consistent color for each name
    private func avatarColor(for name: String) -> Color {
        let colors: [Color] = [
            .featureServices, .statusGoing, Color(hex: "#5B6AF0"),
            Color(hex: "#E05C97"), .featureSongs
        ]
        let idx = abs(name.hashValue) % colors.count
        return colors[idx]
    }
}

// MARK: - Invite Code Section

struct InviteCodeSection: View {
    let band: Band?
    @State private var copied = false

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.featureTeam.opacity(0.14))
                        .frame(width: 30, height: 30)
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.featureTeam)
                }
                Text("Invite Code")
                    .font(.appHeadline)
                    .foregroundColor(.appPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Code display
            Text(band?.inviteCode ?? "------")
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .foregroundColor(.appPrimary)
                .tracking(10)
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .background(Color.appBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.appAccent.opacity(0.40), Color.appAccent.opacity(0.15)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )

            // Actions
            HStack(spacing: 12) {
                Button {
                    AppHaptics.success()
                    UIPasteboard.general.string = band?.inviteCode
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { copied = false }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text(copied ? "Copied!" : "Copy Code")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(copied ? .statusGoing : .appAccent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        copied ? Color.statusGoing.opacity(0.10) : Color.appAccent.opacity(0.10)
                    )
                    .clipShape(Capsule())
                }

                if let band {
                    ShareLink(item: "Join \"\(band.name)\" on Worship Manager! Code: \(band.inviteCode)") {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 13, weight: .semibold))
                            Text("share_invite".localized)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.appPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.appDivider.opacity(0.50))
                        .clipShape(Capsule())
                    }
                }
            }

            Text("Anyone with this code can join your team")
                .font(.appSmall)
                .foregroundColor(.appSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .listRowBackground(Color.appSurface)
    }
}
