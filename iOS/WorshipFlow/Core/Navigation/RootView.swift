import SwiftUI

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var bandVM = BandViewModel()

    @State private var hasLoadedBands = false

    var body: some View {
        Group {
            if authVM.isAuthenticated {
                if bandVM.currentBand != nil {
                    MainTabView()
                        .environmentObject(bandVM)
                } else if !hasLoadedBands || bandVM.isLoading {
                    VStack(spacing: 24) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 180)
                        ProgressView()
                            .tint(.appAccent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBackground)
                } else {
                    BandOnboardingView()
                        .environmentObject(bandVM)
                }
            } else {
                WelcomeView()
            }
        }
        .task {
            if authVM.isAuthenticated {
                await bandVM.loadMyBands()
                hasLoadedBands = true
            }
        }
        .onChange(of: authVM.isAuthenticated) { _, isAuth in
            if isAuth {
                Task {
                    await bandVM.loadMyBands()
                    hasLoadedBands = true
                }
            } else {
                bandVM.currentBand = nil
                bandVM.bands = []
                hasLoadedBands = false
            }
        }
        // Invite code sheet — shown AFTER MainTabView is already on screen
        .sheet(isPresented: Binding<Bool>(
            get: { bandVM.newlyCreatedBand != nil },
            set: { if !$0 { bandVM.newlyCreatedBand = nil } }
        )) {
            if let band = bandVM.newlyCreatedBand {
                InviteCodeSuccessView(band: band) {
                    bandVM.newlyCreatedBand = nil
                }
            }
        }
    }
}

struct BandOnboardingView: View {
    @State private var showCreate = false
    @State private var showJoin = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 12) {
                    Text("🎸")
                        .font(.system(size: 56))

                    Text("Get Started")
                        .font(.appLargeTitle)
                        .foregroundColor(.appPrimary)

                    Text("Create a new band or join an existing one")
                        .font(.appBody)
                        .foregroundColor(.appSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 16) {
                    Button { showCreate = true } label: {
                        VStack(spacing: 8) {
                            Text("create_band".localized)
                                .font(.appHeadline)
                            Text("create_band_subtitle".localized)
                                .font(.appCaption)
                                .foregroundColor(.appSecondary)
                        }
                        .primaryButton()
                    }

                    Button { showJoin = true } label: {
                        VStack(spacing: 8) {
                            Text("join_band".localized)
                                .font(.appHeadline)
                            Text("join_band_subtitle".localized)
                                .font(.appCaption)
                                .foregroundColor(.appSecondary)
                        }
                        .secondaryButton()
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .background(Color.appBackground)
            .navigationDestination(isPresented: $showCreate) {
                CreateBandView()
            }
            .navigationDestination(isPresented: $showJoin) {
                JoinBandView()
            }
        }
    }
}

struct InviteCodeSuccessView: View {
    let band: Band
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("🎉")
                .font(.system(size: 64))

            Text("Band Created!")
                .font(.appLargeTitle)
                .foregroundColor(.appPrimary)

            Text("Share this code with your band members")
                .font(.appBody)
                .foregroundColor(.appSecondary)

            Text(band.inviteCode)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(.appPrimary)
                .padding(24)
                .background(Color.appBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            HStack(spacing: 16) {
                Button {
                    UIPasteboard.general.string = band.inviteCode
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .secondaryButton()
                }

                ShareLink(item: "Join my band \"\(band.name)\" on WorshipFlow! Code: \(band.inviteCode)") {
                    Label("share_invite".localized, systemImage: "square.and.arrow.up")
                        .primaryButton()
                }
            }

            Spacer()

            Button("Continue", action: onDismiss)
                .font(.appHeadline)
                .foregroundColor(.appAccent)
                .padding(.bottom, 32)
        }
        .padding(24)
        .background(Color.appSurface)
    }
}
