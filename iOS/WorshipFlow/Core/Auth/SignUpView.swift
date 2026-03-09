import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var selectedInstrument = "Guitar"

    private let instruments = ["Guitar", "Bass", "Drums", "Keys", "Vocals", "Other"]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("sign_up".localized)
                        .font(.appLargeTitle)
                        .foregroundColor(.appPrimary)

                    Text("Join your worship team")
                        .font(.appBody)
                        .foregroundColor(.appSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 16) {
                    TextField("full_name".localized, text: $name)
                        .appTextField()
                        .textContentType(.name)

                    TextField("email".localized, text: $email)
                        .appTextField()
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("password".localized, text: $password)
                        .appTextField()
                        .textContentType(.newPassword)

                    // Instrument picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("instrument".localized)
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(instruments, id: \.self) { inst in
                                    Button {
                                        selectedInstrument = inst
                                    } label: {
                                        Text(inst)
                                            .font(.appCaption)
                                            .foregroundColor(
                                                selectedInstrument == inst ? .white : .appPrimary
                                            )
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                selectedInstrument == inst
                                                    ? Color.appPrimary
                                                    : Color.appSurface
                                            )
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.appDivider, lineWidth: selectedInstrument == inst ? 0 : 1)
                                            )
                                    }
                                }
                            }
                        }
                    }
                }

                if let error = authVM.error {
                    Text(error)
                        .font(.appCaption)
                        .foregroundColor(.statusNo)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                LoadingButton(
                    title: "sign_up".localized,
                    isLoading: authVM.isLoading
                ) {
                    Task {
                        await authVM.signUp(
                            email: email,
                            password: password,
                            name: name,
                            instrument: selectedInstrument
                        )
                    }
                }
            }
            .padding(24)
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
    }
}
