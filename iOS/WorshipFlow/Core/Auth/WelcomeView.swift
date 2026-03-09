import SwiftUI

struct WelcomeView: View {
    @State private var showLogin = false
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                // Hero
                VStack(spacing: 16) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 260)

                    Text("app_tagline".localized)
                        .font(.appBody)
                        .foregroundColor(.appSecondary)
                }

                Spacer()

                // Actions
                VStack(spacing: 12) {
                    Button {
                        showSignUp = true
                    } label: {
                        Text("sign_up".localized)
                            .primaryButton()
                    }

                    Button {
                        showLogin = true
                    } label: {
                        Text("sign_in".localized)
                            .secondaryButton()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
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
