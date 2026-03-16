import SwiftUI

struct CreateServiceView: View {
    @ObservedObject var vm: SetlistViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var selectedServiceType = ""
    @State private var includeDate = true
    @State private var date = Date()
    @State private var location = ""
    @State private var theme = ""
    @State private var notes = ""
    @State private var isLoading = false

    private let serviceTypes: [(id: String, label: String, icon: String)] = [
        ("sunday_morning", "Sunday Morning", "sun.max.fill"),
        ("sunday_evening", "Sunday Evening", "moon.stars.fill"),
        ("wednesday",      "Wednesday",       "calendar.badge.clock"),
        ("special",        "Special Event",   "star.fill")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Name
                    fieldSection(label: "Service Name", icon: "text.cursor") {
                        TextField("e.g. Sunday Morning Service", text: $name)
                            .appTextField()
                    }

                    // Service type grid
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Service Type", systemImage: "tag")
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(serviceTypes, id: \.id) { type in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedServiceType = selectedServiceType == type.id ? "" : type.id
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 13))
                                        Text(type.label)
                                            .font(.system(size: 13, weight: .medium))
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                    }
                                    .foregroundColor(selectedServiceType == type.id ? .white : .appPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 11)
                                    .background(selectedServiceType == type.id ? Color.appPrimary : Color.appSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.appDivider, lineWidth: selectedServiceType == type.id ? 0 : 1)
                                    )
                                }
                            }
                        }
                    }

                    // Date
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle(isOn: $includeDate) {
                            Label("Set Date", systemImage: "calendar")
                                .font(.appCaption)
                                .foregroundColor(.appSecondary)
                        }
                        .tint(.appAccent)

                        if includeDate {
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .tint(.appAccent)
                        }
                    }

                    // Location
                    fieldSection(label: "Location (optional)", icon: "mappin.circle") {
                        TextField("Main Sanctuary", text: $location)
                            .appTextField()
                    }

                    // Theme
                    fieldSection(label: "Theme (optional)", icon: "sparkles") {
                        TextField("e.g. Grace, Hope, Renewal...", text: $theme)
                            .appTextField()
                    }

                    // Notes
                    fieldSection(label: "Notes (optional)", icon: "note.text") {
                        TextField("Additional notes...", text: $notes, axis: .vertical)
                            .appTextField()
                            .lineLimit(3...6)
                    }
                }
                .padding(24)
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("New Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Create") {
                            Task { await create() }
                        }
                        .fontWeight(.semibold)
                        .disabled(name.isEmpty)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func fieldSection<Content: View>(label: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.appCaption)
                .foregroundColor(.appSecondary)
            content()
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
            notes: notes.isEmpty ? nil : notes,
            serviceType: selectedServiceType.isEmpty ? nil : selectedServiceType,
            location: location.isEmpty ? nil : location,
            theme: theme.isEmpty ? nil : theme
        )
        isLoading = false
        dismiss()
    }
}
