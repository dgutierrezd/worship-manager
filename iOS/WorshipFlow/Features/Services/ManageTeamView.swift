import SwiftUI

// MARK: - Manage Team View

struct ManageTeamView: View {
    let setlist: Setlist
    @ObservedObject var assignmentVM: ServiceAssignmentViewModel
    @EnvironmentObject var bandVM: BandViewModel
    @Environment(\.dismiss) var dismiss

    @State private var members: [Member] = []
    @State private var showAddSheet = false
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            List {
                if !assignmentVM.assignments.isEmpty {
                    Section("Scheduled (\(assignmentVM.assignments.count))") {
                        ForEach(assignmentVM.assignments) { assignment in
                            AssignmentRow(assignment: assignment)
                        }
                        .onDelete { indexSet in
                            Task {
                                for idx in indexSet {
                                    await assignmentVM.removeAssignment(assignmentVM.assignments[idx])
                                }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        showAddSheet = true
                    } label: {
                        Label("Add Team Member", systemImage: "person.badge.plus")
                            .foregroundColor(.appAccent)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Manage Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddTeamMemberSheet(setlist: setlist, assignmentVM: assignmentVM, members: members)
                    .presentationDetents([.medium, .large])
            }
            .task {
                await loadMembers()
            }
        }
    }

    private func loadMembers() async {
        guard let bandId = bandVM.currentBand?.id else { return }
        do {
            members = try await BandService.getMembers(bandId: bandId)
        } catch {}
    }
}

// MARK: - Add Team Member Sheet

struct AddTeamMemberSheet: View {
    let setlist: Setlist
    @ObservedObject var assignmentVM: ServiceAssignmentViewModel
    let members: [Member]
    @Environment(\.dismiss) var dismiss

    @State private var selectedMemberId: String?
    @State private var selectedRole = "musician"
    @State private var instrument = ""
    @State private var isLoading = false

    private let roles: [(id: String, label: String, icon: String)] = [
        ("leader",    "Worship Leader", "music.mic"),
        ("musician",  "Musician",       "guitars"),
        ("vocalist",  "Vocalist",       "mic"),
        ("tech",      "Tech",           "slider.horizontal.3"),
        ("volunteer", "Volunteer",      "hand.raised")
    ]

    var availableMembers: [Member] {
        let assigned = Set(assignmentVM.assignments.map { $0.userId })
        return members.filter { !assigned.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Select Member") {
                    if availableMembers.isEmpty {
                        Text("All members are already assigned")
                            .font(.appBody)
                            .foregroundColor(.appSecondary)
                    } else {
                        ForEach(availableMembers) { member in
                            Button {
                                selectedMemberId = member.id
                            } label: {
                                HStack {
                                    // Mini avatar
                                    ZStack {
                                        Circle()
                                            .fill(Color.appDivider)
                                            .frame(width: 32, height: 32)
                                        Text(String(member.fullName.prefix(1)).uppercased())
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.appSecondary)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(member.fullName)
                                            .font(.appHeadline)
                                            .foregroundColor(.appPrimary)
                                        if let instrument = member.instrument {
                                            Text(instrument)
                                                .font(.appCaption)
                                                .foregroundColor(.appSecondary)
                                        }
                                    }

                                    Spacer()

                                    if selectedMemberId == member.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.appAccent)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Role") {
                    ForEach(roles, id: \.id) { role in
                        Button {
                            selectedRole = role.id
                        } label: {
                            HStack {
                                Label(role.label, systemImage: role.icon)
                                    .foregroundColor(.appPrimary)
                                Spacer()
                                if selectedRole == role.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.appAccent)
                                }
                            }
                        }
                    }
                }

                if selectedRole == "musician" {
                    Section("Instrument (optional)") {
                        TextField("Guitar, Piano, Bass, Drums...", text: $instrument)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Add") {
                            Task { await add() }
                        }
                        .fontWeight(.semibold)
                        .disabled(selectedMemberId == nil)
                    }
                }
            }
        }
    }

    private func add() async {
        guard let memberId = selectedMemberId else { return }
        isLoading = true
        let success = await assignmentVM.addAssignment(
            setlistId: setlist.id,
            userId: memberId,
            role: selectedRole,
            instrument: instrument.isEmpty ? nil : instrument
        )
        isLoading = false
        if success { dismiss() }
    }
}
