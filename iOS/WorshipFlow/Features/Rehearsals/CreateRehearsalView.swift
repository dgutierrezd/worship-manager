import SwiftUI

struct CreateRehearsalView: View {
    @ObservedObject var vm: RehearsalsViewModel
    @EnvironmentObject var bandVM: BandViewModel
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var location = ""
    @State private var scheduledAt = Date()
    @State private var notes = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TextField("rehearsal_title".localized, text: $title)
                        .appTextField()

                    TextField("location".localized, text: $location)
                        .appTextField()

                    DatePicker(
                        "date_time".localized,
                        selection: $scheduledAt,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .tint(.appAccent)

                    TextField("Notes", text: $notes, axis: .vertical)
                        .appTextField()
                        .lineLimit(3...6)
                }
                .padding(24)
            }
            .background(Color.appBackground)
            .navigationTitle("new_rehearsal".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task { await create() }
                    }
                    .disabled(title.isEmpty || isLoading)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func create() async {
        guard let bandId = bandVM.currentBand?.id else { return }
        isLoading = true
        let success = await vm.createRehearsal(
            bandId: bandId,
            title: title,
            location: location.isEmpty ? nil : location,
            scheduledAt: scheduledAt,
            notes: notes.isEmpty ? nil : notes,
            setlistId: nil
        )
        isLoading = false
        if success { dismiss() }
    }
}
