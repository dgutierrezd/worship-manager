import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("sign_in".localized)
                    .font(.appLargeTitle)
                    .foregroundColor(.appPrimary)

                Text("Welcome back")
                    .font(.appBody)
                    .foregroundColor(.appSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 16) {
                TextField("email".localized, text: $email)
                    .appTextField()
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("password".localized, text: $password)
                    .appTextField()
                    .textContentType(.password)
            }

            if let error = authVM.error {
                Text(error)
                    .font(.appCaption)
                    .foregroundColor(.statusNo)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            LoadingButton(
                title: "sign_in".localized,
                isLoading: authVM.isLoading
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
