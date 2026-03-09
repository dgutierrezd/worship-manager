import SwiftUI

@MainActor
class RehearsalsViewModel: ObservableObject {
    @Published var rehearsals: [Rehearsal] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var myRSVP: String?

    var nextRehearsal: Rehearsal? {
        rehearsals.first { !$0.isPast }
    }

    var upcomingRehearsals: [Rehearsal] {
        rehearsals.filter { !$0.isPast }
    }

    var pastRehearsals: [Rehearsal] {
        rehearsals.filter { $0.isPast }
    }

    func loadRehearsals(bandId: String) async {
        isLoading = true
        do {
            rehearsals = try await RehearsalService.getRehearsals(bandId: bandId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func createRehearsal(bandId: String, title: String, location: String?, scheduledAt: Date, notes: String?, setlistId: String?) async -> Bool {
        do {
            let iso = ISO8601DateFormatter().string(from: scheduledAt)
            let rehearsal = try await RehearsalService.createRehearsal(
                bandId: bandId, title: title, location: location,
                scheduledAt: iso, notes: notes, setlistId: setlistId
            )
            rehearsals.append(rehearsal)
            rehearsals.sort { $0.scheduledAt < $1.scheduledAt }
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func deleteRehearsal(_ rehearsal: Rehearsal) async {
        do {
            try await RehearsalService.deleteRehearsal(id: rehearsal.id)
            rehearsals.removeAll { $0.id == rehearsal.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func rsvp(rehearsalId: String, status: String) async {
        do {
            let response = try await RehearsalService.rsvp(rehearsalId: rehearsalId, status: status)
            myRSVP = response.status
        } catch {
            self.error = error.localizedDescription
        }
    }
}
