import SwiftUI

struct MemberProfileView: View {
    let member: Member
    let bandId: String
    @EnvironmentObject var bandVM: BandViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showRemoveAlert = false

    var isLeader: Bool { bandVM.currentBand?.isLeader == true }

    var body: some View {
        VStack(spacing: 24) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.appDivider)
                    .frame(width: 80, height: 80)

                Text(String(member.fullName.prefix(1)).uppercased())
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.appSecondary)
            }

            VStack(spacing: 6) {
                Text(member.fullName)
                    .font(.appTitle)
                    .foregroundColor(.appPrimary)

                if let instrument = member.instrument {
                    Text(instrument)
                        .font(.appBody)
                        .foregroundColor(.appSecondary)
                }

                Text(member.isLeader
                     ? "leader".localized
                     : "member_role".localized)
                    .font(.appCaption)
                    .foregroundColor(.appAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.appAccent.opacity(0.15))
                    .clipShape(Capsule())
            }

            Spacer()

            if isLeader && member.id != bandVM.currentBand?.createdBy {
                VStack(spacing: 12) {
                    Button {
                        Task {
                            let newRole = member.isLeader ? "member" : "leader"
                            _ = try? await BandService.updateMemberRole(
                                bandId: bandId, userId: member.id, role: newRole
                            )
                            dismiss()
                        }
                    } label: {
                        Text(member.isLeader ? "Demote to Member" : "Promote to Leader")
                            .secondaryButton()
                    }

                    Button { showRemoveAlert = true } label: {
                        Text("remove_member".localized)
                            .font(.appHeadline)
                            .foregroundColor(.statusNo)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.vertical, 32)
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Remove Member?", isPresented: $showRemoveAlert) {
            Button("Remove", role: .destructive) {
                Task {
                    try? await BandService.removeMember(bandId: bandId, userId: member.id)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
