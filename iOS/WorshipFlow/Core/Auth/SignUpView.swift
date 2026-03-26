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
            VStack(spacing: 28) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppGradients.gold)
                                .frame(width: 40, height: 40)
                            Image(systemName: "person.fill.badge.plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("sign_up".localized)
                            .font(.appLargeTitle)
                            .foregroundColor(.appPrimary)
                    }

                    Text("Join your worship team")
                        .font(.appBody)
                        .foregroundColor(.appSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

                // Fields
                VStack(spacing: 14) {
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
                    VStack(alignment: .leading, spacing: 10) {
                        Text("instrument".localized)
                            .font(.appSmall)
                            .foregroundColor(.appSecondary)
                            .fontWeight(.semibold)
                            .tracking(0.8)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(instruments, id: \.self) { inst in
                                    Button {
                                        AppHaptics.selection()
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                            selectedInstrument = inst
                                        }
                                    } label: {
                                        Text(inst)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(selectedInstrument == inst ? .white : .appPrimary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                Group {
                                                    if selectedInstrument == inst {
                                                        AnyView(AppGradients.gold)
                                                    } else {
                                                        AnyView(Color.appSurface)
                                                    }
                                                }
                                            )
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(
                                                        selectedInstrument == inst ? Color.clear : Color.appDivider,
                                                        lineWidth: 1
                                                    )
                                            )
                                            .shadow(
                                                color: selectedInstrument == inst ? Color.appAccent.opacity(0.30) : .clear,
                                                radius: 5, x: 0, y: 2
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appDivider, lineWidth: 1.5))
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
                    title: "sign_up".localized,
                    isLoading: authVM.isLoading,
                    style: .accent
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
