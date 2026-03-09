import SwiftUI

struct RehearsalDetailView: View {
    let rehearsal: Rehearsal
    @ObservedObject var vm: RehearsalsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text(rehearsal.title)
                        .font(.appLargeTitle)
                        .foregroundColor(.appPrimary)

                    HStack(spacing: 16) {
                        Label(rehearsal.formattedDate, systemImage: "calendar")
                            .font(.appBody)
                            .foregroundColor(.appSecondary)

                        Text(rehearsal.formattedTime)
                            .font(.appBody)
                            .foregroundColor(.appSecondary)
                    }

                    if let location = rehearsal.location {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .font(.appBody)
                            .foregroundColor(.appSecondary)
                    }
                }
                .padding(.top, 16)

                // Linked Setlist
                if let setlistName = rehearsal.setlists?.name {
                    HStack {
                        Image(systemName: "music.note.list")
                            .foregroundColor(.appAccent)
                        Text("linked_setlist".localized)
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)
                        Text(setlistName)
                            .font(.appHeadline)
                            .foregroundColor(.appPrimary)
                        Spacer()
                    }
                    .padding(16)
                    .cardStyle()
                    .padding(.horizontal)
                }

                // RSVP
                VStack(spacing: 12) {
                    Text("Your Response")
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)

                    HStack(spacing: 12) {
                        RSVPButton(
                            title: "rsvp_going".localized,
                            icon: "checkmark",
                            color: .statusGoing,
                            isSelected: vm.myRSVP == "going"
                        ) {
                            Task { await vm.rsvp(rehearsalId: rehearsal.id, status: "going") }
                        }

                        RSVPButton(
                            title: "rsvp_maybe".localized,
                            icon: "questionmark",
                            color: .statusMaybe,
                            isSelected: vm.myRSVP == "maybe"
                        ) {
                            Task { await vm.rsvp(rehearsalId: rehearsal.id, status: "maybe") }
                        }

                        RSVPButton(
                            title: "rsvp_no".localized,
                            icon: "xmark",
                            color: .statusNo,
                            isSelected: vm.myRSVP == "not_going"
                        ) {
                            Task { await vm.rsvp(rehearsalId: rehearsal.id, status: "not_going") }
                        }
                    }
                }
                .padding(16)
                .cardStyle()
                .padding(.horizontal)

                // Notes
                if let notes = rehearsal.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)

                        Text(notes)
                            .font(.appBody)
                            .foregroundColor(.appPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .cardStyle()
                    .padding(.horizontal)
                }

                Spacer()
            }
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
    }
}
