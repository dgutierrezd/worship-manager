import SwiftUI

struct CreateSetlistView: View {
    @ObservedObject var vm: SetlistViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var date = Date()
    @State private var includeDate = true
    @State private var notes = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TextField("setlist_name".localized, text: $name)
                        .appTextField()

                    Toggle("Include date", isOn: $includeDate)
                        .tint(.appAccent)

                    if includeDate {
                        DatePicker(
                            "date_time".localized,
                            selection: $date,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .tint(.appAccent)
                    }

                    TextField("Notes", text: $notes, axis: .vertical)
                        .appTextField()
                        .lineLimit(3...6)
                }
                .padding(24)
            }
            .background(Color.appBackground)
            .navigationTitle("new_setlist".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task { await create() }
                    }
                    .disabled(name.isEmpty || isLoading)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func create() async {
        isLoading = true
        let dateStr: String? = includeDate ? {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: date)
        }() : nil

        let _ = await vm.createSetlist(
            name: name,
            date: dateStr,
            notes: notes.isEmpty ? nil : notes
        )
        isLoading = false
        dismiss()
    }
}
