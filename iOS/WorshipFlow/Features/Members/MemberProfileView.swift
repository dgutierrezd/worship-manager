import SwiftUI

struct MemberProfileView: View {
    let member: Member
    let bandId: String
    @EnvironmentObject var bandVM: BandViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showRemoveAlert = false

    // All band members are treated equally — leader privileges are not surfaced in the UI.
    var canManage: Bool { bandVM.currentBand?.isLeader == true }

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

            }

            Spacer()

            // Only band creator can remove members — role promotion/demotion UI removed.
            if canManage && member.id != bandVM.currentBand?.createdBy {
                Button { showRemoveAlert = true } label: {
                    Text("remove_member".localized)
                        .font(.appHeadline)
                        .foregroundColor(.statusNo)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
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
