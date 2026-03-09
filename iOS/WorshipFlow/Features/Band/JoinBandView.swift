import SwiftUI

struct JoinBandView: View {
    @EnvironmentObject var bandVM: BandViewModel
    @Environment(\.dismiss) var dismiss

    @State private var code = ""
    @State private var shake = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text("join_band".localized)
                    .font(.appLargeTitle)
                    .foregroundColor(.appPrimary)

                Text("invite_code_hint".localized)
                    .font(.appBody)
                    .foregroundColor(.appSecondary)
            }

            TextField("WF3K9X", text: $code)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
                .padding(20)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appDivider, lineWidth: 1)
                )
                .padding(.horizontal, 48)
                .offset(x: shake ? -10 : 0)
                .onChange(of: code) { _, newValue in
                    code = String(newValue.prefix(6)).uppercased()
                    if code.count == 6 {
                        Task { await joinWithCode() }
                    }
                }

            if bandVM.isLoading {
                ProgressView()
                    .tint(.appPrimary)
            }

            Spacer()
            Spacer()
        }
        .padding(24)
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { bandVM.error = nil }
        .alert("Error", isPresented: Binding<Bool>(
            get: { bandVM.error != nil },
            set: { if !$0 { bandVM.error = nil } }
        )) {
            Button("OK") { bandVM.error = nil }
        } message: {
            Text(bandVM.error ?? "")
        }
    }

    private func joinWithCode() async {
        // joinBand sets currentBand → RootView swaps to MainTabView
        let success = await bandVM.joinBand(code: code)
        if !success {
            withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) {
                shake = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                shake = false
            }
        }
    }
}
