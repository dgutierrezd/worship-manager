import SwiftUI

struct MembersView: View {
    @EnvironmentObject var bandVM: BandViewModel
    @State private var members: [Member] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(members) { member in
                        NavigationLink {
                            MemberProfileView(member: member, bandId: bandVM.currentBand?.id ?? "")
                        } label: {
                            MemberRow(member: member)
                        }
                    }
                }

                Section {
                    InviteCodeSection(band: bandVM.currentBand)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("members".localized)
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

struct MemberRow: View {
    let member: Member

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.appDivider)
                    .frame(width: 44, height: 44)

                Text(String(member.fullName.prefix(1)).uppercased())
                    .font(.appHeadline)
                    .foregroundColor(.appSecondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(member.fullName)
                        .font(.appHeadline)
                        .foregroundColor(.appPrimary)

                    if member.isLeader {
                        Text("leader".localized)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.appAccent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appAccent.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                if let instrument = member.instrument {
                    Text(instrument)
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct InviteCodeSection: View {
    let band: Band?

    var body: some View {
        VStack(spacing: 12) {
            Text("invite_code".localized)
                .font(.appCaption)
                .foregroundColor(.appSecondary)

            Text(band?.inviteCode ?? "------")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(.appPrimary)

            HStack(spacing: 16) {
                Button {
                    UIPasteboard.general.string = band?.inviteCode
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.appCaption)
                        .foregroundColor(.appAccent)
                }

                if let band {
                    ShareLink(
                        item: "Join \"\(band.name)\" on WorshipFlow! Code: \(band.inviteCode)"
                    ) {
                        Label("share_invite".localized, systemImage: "square.and.arrow.up")
                            .font(.appCaption)
                            .foregroundColor(.appAccent)
                    }
                }
            }

            Text("Anyone with this code can join your band")
                .font(.appCaption)
                .foregroundColor(.appSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
