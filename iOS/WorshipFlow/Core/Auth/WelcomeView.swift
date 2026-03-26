import SwiftUI

struct WelcomeView: View {
    @State private var showLogin = false
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Hero gradient background
                VStack(spacing: 0) {
                    AppGradients.hero
                        .frame(height: 420)
                    Color.appBackground
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Logo + tagline
                    VStack(spacing: 20) {
                        // App icon placeholder with gold gradient ring
                        ZStack {
                            Circle()
                                .fill(AppGradients.gold)
                                .frame(width: 104, height: 104)
                            Circle()
                                .fill(Color.appBackground)
                                .frame(width: 96, height: 96)
                            Image(systemName: "music.quarternote.3")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(AppGradients.gold)
                        }
                        .shadow(color: Color.appAccent.opacity(0.30), radius: 18, x: 0, y: 6)

                        VStack(spacing: 8) {
                            Text("WorshipFlow")
                                .font(.appLargeTitle)
                                .foregroundColor(.appPrimary)

                            Text("app_tagline".localized)
                                .font(.appBody)
                                .foregroundColor(.appSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Spacer()
                    Spacer()

                    // Actions
                    VStack(spacing: 14) {
                        Button {
                            AppHaptics.medium()
                            showSignUp = true
                        } label: {
                            Text("sign_up".localized)
                                .accentButton()
                        }
                        .pressable()

                        Button {
                            AppHaptics.light()
                            showLogin = true
                        } label: {
                            Text("sign_in".localized)
                                .secondaryButton()
                        }
                        .pressable()
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 52)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
            .navigationDestination(isPresented: $showLogin) {
                LoginView()
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }
}
