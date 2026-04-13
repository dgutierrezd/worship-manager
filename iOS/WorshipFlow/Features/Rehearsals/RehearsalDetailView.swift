import SwiftUI

struct RehearsalDetailView: View {
    let rehearsal: Rehearsal
    @ObservedObject var vm: RehearsalsViewModel
    @State private var calendarAdded = false
    @State private var showCalendarError = false

    // Attendance roster for this rehearsal
    @State private var rosterRSVPs: [AttendanceRSVP] = []
    @State private var rosterLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // MARK: Hero Header
                VStack(spacing: 0) {
                    // Gold accent bar at top
                    AppGradients.gold
                        .frame(height: 4)
                        .clipShape(RoundedRectangle(cornerRadius: 2))

                    VStack(spacing: 14) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(Color.featureSchedule.opacity(0.14))
                                .frame(width: 64, height: 64)
                            Image(systemName: "calendar")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(.featureSchedule)
                        }

                        Text(rehearsal.title)
                            .font(.appLargeTitle)
                            .foregroundColor(.appPrimary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Label(rehearsal.formattedDate, systemImage: "calendar")
                                .font(.appBody)
                                .foregroundColor(.appSecondary)
                            Text("·")
                                .foregroundColor(.appDivider)
                            Text(rehearsal.formattedTime)
                                .font(.appBody)
                                .foregroundColor(.appSecondary)
                        }

                        if let location = rehearsal.location {
                            Label(location, systemImage: "mappin.circle.fill")
                                .font(.appBody)
                                .foregroundColor(.appSecondary)
                        }
                    }
                    .padding(24)
                }
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.07), radius: 14, x: 0, y: 4)
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // MARK: Linked Setlist
                if let setlistName = rehearsal.setlists?.name {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.featureServices.opacity(0.14))
                                .frame(width: 38, height: 38)
                            Image(systemName: "music.note.list")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.featureServices)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("linked_setlist".localized)
                                .font(.appSmall)
                                .foregroundColor(.appSecondary)
                                .fontWeight(.semibold)
                            Text(setlistName)
                                .font(.appHeadline)
                                .foregroundColor(.appPrimary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.appSecondary.opacity(0.4))
                    }
                    .padding(16)
                    .cardStyle()
                    .padding(.horizontal, 20)
                }

                // MARK: RSVP Card
                VStack(spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Your Response")
                                .font(.appHeadline)
                                .foregroundColor(.appPrimary)
                            Text("Let your band know if you'll be there")
                                .font(.appSmall)
                                .foregroundColor(.appSecondary)
                        }
                        Spacer()
                    }

                    Divider().opacity(0.4)

                    HStack(spacing: 10) {
                        RSVPButton(
                            title: "rsvp_going".localized,
                            icon: "checkmark",
                            color: .statusGoing,
                            isSelected: vm.rsvpStatus(for: rehearsal.id) == "going"
                        ) {
                            Task { await vm.rsvp(rehearsalId: rehearsal.id, status: "going") }
                        }
                        .frame(maxWidth: .infinity)

                        RSVPButton(
                            title: "rsvp_maybe".localized,
                            icon: "questionmark",
                            color: .statusMaybe,
                            isSelected: vm.rsvpStatus(for: rehearsal.id) == "maybe"
                        ) {
                            Task { await vm.rsvp(rehearsalId: rehearsal.id, status: "maybe") }
                        }
                        .frame(maxWidth: .infinity)

                        RSVPButton(
                            title: "rsvp_no".localized,
                            icon: "xmark",
                            color: .statusNo,
                            isSelected: vm.rsvpStatus(for: rehearsal.id) == "not_going"
                        ) {
                            Task { await vm.rsvp(rehearsalId: rehearsal.id, status: "not_going") }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(18)
                .featuredCardStyle()
                .padding(.horizontal, 20)

                // MARK: Add to Calendar
                Button {
                    Task { await addToCalendar() }
                } label: {
                    HStack {
                        Spacer()
                        Label(
                            calendarAdded ? "added_to_calendar".localized : "add_to_calendar".localized,
                            systemImage: calendarAdded ? "checkmark.circle.fill" : "calendar.badge.plus"
                        )
                        .font(.appHeadline)
                        .foregroundColor(calendarAdded ? .statusGoing : .appAccent)
                        Spacer()
                    }
                    .padding(16)
                    .cardStyle()
                }
                .disabled(calendarAdded)
                .padding(.horizontal, 20)
                .alert("Could not add to calendar. Please allow calendar access in Settings.", isPresented: $showCalendarError) {
                    Button("OK", role: .cancel) {}
                }

                // MARK: Attendance Roster
                AttendanceRosterCard(rsvps: rosterRSVPs, isLoading: rosterLoading)
                    .padding(.horizontal, 20)

                // MARK: Notes
                if let notes = rehearsal.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "note.text")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.appAccent)
                            Text("Notes")
                                .font(.appHeadline)
                                .foregroundColor(.appPrimary)
                        }

                        Text(notes)
                            .font(.appBody)
                            .foregroundColor(.appSecondary)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .cardStyle()
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 32)
            }
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadRoster() }
        .onChange(of: vm.rsvpStatus(for: rehearsal.id)) { _, _ in
            Task { await loadRoster() }
        }
    }

    private func loadRoster() async {
        rosterLoading = true
        defer { rosterLoading = false }
        do {
            rosterRSVPs = try await RehearsalService.getRSVPs(rehearsalId: rehearsal.id)
        } catch {
            // Non-fatal — roster simply stays empty.
        }
    }

    private func addToCalendar() async {
        guard let startDate = rehearsal.scheduledDate else { return }
        let success = await CalendarService.addEvent(
            title: rehearsal.title,
            startDate: startDate,
            location: rehearsal.location,
            notes: rehearsal.notes
        )
        if success {
            calendarAdded = true
        } else {
            showCalendarError = true
        }
    }
}
