import SwiftUI

@MainActor
class RehearsalsViewModel: ObservableObject {
    @Published var rehearsals: [Rehearsal] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var rsvpStatuses: [String: String] = [:]

    var nextRehearsal: Rehearsal? {
        rehearsals.first { !$0.isPast }
    }

    var upcomingRehearsals: [Rehearsal] {
        rehearsals.filter { !$0.isPast }
    }

    var pastRehearsals: [Rehearsal] {
        rehearsals.filter { $0.isPast }
    }

    func rsvpStatus(for rehearsalId: String) -> String? {
        rsvpStatuses[rehearsalId]
    }

    func loadRehearsals(bandId: String) async {
        isLoading = true
        do {
            async let rehearsalsTask = RehearsalService.getRehearsals(bandId: bandId)
            async let rsvpsTask = RehearsalService.getMyRSVPs(bandId: bandId)
            let (loadedRehearsals, loadedRSVPs) = try await (rehearsalsTask, rsvpsTask)
            rehearsals = loadedRehearsals
            var statuses: [String: String] = [:]
            for rsvp in loadedRSVPs {
                if let rid = rsvp.rehearsalId {
                    statuses[rid] = rsvp.status
                }
            }
            rsvpStatuses = statuses
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
            rsvpStatuses[rehearsalId] = response.status
        } catch {
            self.error = error.localizedDescription
        }
    }
}
