import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var name: String = ""
    @State private var instrument: String = "Guitar"

    private let instruments = ["Guitar", "Bass", "Drums", "Keys", "Vocals", "Other"]

    var body: some View {
        List {
            Section("full_name".localized) {
                TextField("full_name".localized, text: $name)
            }

            Section("instrument".localized) {
                Picker("instrument".localized, selection: $instrument) {
                    ForEach(instruments, id: \.self) { inst in
                        Text(inst).tag(inst)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
        }
        .navigationTitle("profile".localized)
        .onAppear {
            name = authVM.profile?.fullName ?? ""
            instrument = authVM.profile?.instrument ?? "Guitar"
        }
    }
}
