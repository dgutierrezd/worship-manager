import SwiftUI

struct InviteView: View {
    let band: Band

    @State private var copied = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("invite_code".localized)
                .font(.appTitle)
                .foregroundColor(.appPrimary)

            Text(band.inviteCode)
                .font(.system(size: 44, weight: .bold, design: .monospaced))
                .foregroundColor(.appPrimary)
                .padding(32)
                .background(Color.appBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            if copied {
                Text("code_copied".localized)
                    .font(.appCaption)
                    .foregroundColor(.statusGoing)
                    .transition(.opacity)
            }

            HStack(spacing: 16) {
                Button {
                    UIPasteboard.general.string = band.inviteCode
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { copied = false }
                    }
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .secondaryButton()
                }

                ShareLink(
                    item: "Join \"\(band.name)\" on WorshipFlow! Code: \(band.inviteCode)"
                ) {
                    Label("share_invite".localized, systemImage: "square.and.arrow.up")
                        .primaryButton()
                }
            }

            Spacer()
        }
        .padding(24)
        .background(Color.appSurface)
    }
}
