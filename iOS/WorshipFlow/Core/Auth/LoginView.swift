import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 28) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppGradients.gold)
                            .frame(width: 40, height: 40)
                        Image(systemName: "music.quarternote.3")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("sign_in".localized)
                        .font(.appLargeTitle)
                        .foregroundColor(.appPrimary)
                }

                Text("Welcome back")
                    .font(.appBody)
                    .foregroundColor(.appSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)

            // Fields
            VStack(spacing: 14) {
                TextField("email".localized, text: $email)
                    .appTextField()
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("password".localized, text: $password)
                    .appTextField()
                    .textContentType(.password)
            }

            // Error
            if let error = authVM.error {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                    Text(error)
                        .font(.appCaption)
                }
                .foregroundColor(.statusNo)
                .padding(12)
                .background(Color.statusNo.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            LoadingButton(
                title: "sign_in".localized,
                isLoading: authVM.isLoading,
                style: .accent
            ) {
                Task { await authVM.signIn(email: email, password: password) }
            }

            Spacer()
        }
        .padding(24)
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
    }
}
