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

    // Setlist picker
    @State private var setlists: [Setlist] = []
    @State private var selectedSetlistId: String? = nil

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

                    setlistPicker

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
            .task { await loadSetlists() }
        }
    }

    // MARK: - Setlist picker

    /// Optional dropdown to link this rehearsal to one of the band's
    /// existing services. Selected setlist appears on the rehearsal card
    /// and can be opened directly from the rehearsal detail.
    private var setlistPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("link_setlist_optional".localized, systemImage: "music.note.list")
                .font(.appCaption)
                .foregroundColor(.appSecondary)

            Menu {
                Button("none".localized) { selectedSetlistId = nil }
                Divider()
                ForEach(setlists) { sl in
                    Button {
                        selectedSetlistId = sl.id
                    } label: {
                        HStack {
                            Text(sl.name)
                            if let formatted = sl.formattedDate {
                                Spacer()
                                Text(formatted)
                            }
                            if selectedSetlistId == sl.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedSetlistTitle)
                        .font(.appBody)
                        .foregroundColor(selectedSetlistId == nil ? .appSecondary : .appPrimary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.appSecondary)
                }
                .padding(16)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.appDivider, lineWidth: 1.5)
                )
            }
        }
    }

    private var selectedSetlistTitle: String {
        guard let id = selectedSetlistId,
              let sl = setlists.first(where: { $0.id == id }) else {
            return setlists.isEmpty
                ? "no_setlists_yet".localized
                : "choose_setlist".localized
        }
        return sl.name
    }

    private func loadSetlists() async {
        guard let bandId = bandVM.currentBand?.id else { return }
        do {
            setlists = try await SetlistService.getSetlists(bandId: bandId)
        } catch {
            // Non-fatal — picker will just show "no setlists yet".
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
            setlistId: selectedSetlistId
        )
        isLoading = false
        if success { dismiss() }
    }
}
