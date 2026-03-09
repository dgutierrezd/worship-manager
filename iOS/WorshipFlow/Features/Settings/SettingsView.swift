import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var bandVM: BandViewModel

    var body: some View {
        List {
            Section("profile".localized) {
                NavigationLink {
                    ProfileView()
                } label: {
                    Label("profile".localized, systemImage: "person.circle")
                }
            }

            Section("my_bands".localized) {
                ForEach(bandVM.bands) { band in
                    Button {
                        bandVM.switchBand(band)
                    } label: {
                        HStack(spacing: 12) {
                            BandAvatarView(band: band, size: 32)
                            Text(band.name)
                                .foregroundColor(.appPrimary)
                            Spacer()
                            if band.id == bandVM.currentBand?.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.appAccent)
                            }
                        }
                    }
                }
            }

            if bandVM.currentBand?.isLeader == true {
                Section("Band") {
                    NavigationLink {
                        BandSettingsView()
                    } label: {
                        Label("Band Settings", systemImage: "gearshape.2")
                    }
                }
            }

            Section {
                NavigationLink {
                    LanguageView()
                } label: {
                    Label("language".localized, systemImage: "globe")
                }
            }

            Section {
                Button(role: .destructive) {
                    Task { await authVM.signOut() }
                } label: {
                    Label("sign_out".localized, systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.statusNo)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("settings".localized)
        .background(Color.appBackground)
    }
}
