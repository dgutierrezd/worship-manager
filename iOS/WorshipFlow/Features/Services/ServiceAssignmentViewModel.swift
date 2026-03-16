import SwiftUI

@MainActor
class ServiceAssignmentViewModel: ObservableObject {
    @Published var assignments: [ServiceAssignment] = []
    @Published var isLoading = false
    @Published var error: String?

    private var currentSetlistId: String?

    func loadAssignments(setlistId: String) async {
        currentSetlistId = setlistId
        isLoading = true
        do {
            assignments = try await ServiceAssignmentService.getServiceAssignments(setlistId: setlistId)
        } catch {
            // Non-critical — endpoint may not exist yet; show empty state
            assignments = []
        }
        isLoading = false
    }

    func addAssignment(setlistId: String, userId: String, role: String, instrument: String?) async -> Bool {
        do {
            let assignment = try await ServiceAssignmentService.addServiceAssignment(
                setlistId: setlistId,
                userId: userId,
                role: role,
                instrument: instrument,
                notes: nil
            )
            assignments.append(assignment)
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func updateStatus(_ assignment: ServiceAssignment, status: String) async {
        do {
            let updated = try await ServiceAssignmentService.updateServiceAssignment(
                assignmentId: assignment.id,
                role: nil,
                status: status,
                instrument: nil
            )
            if let idx = assignments.firstIndex(where: { $0.id == assignment.id }) {
                assignments[idx] = updated
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func removeAssignment(_ assignment: ServiceAssignment) async {
        do {
            try await ServiceAssignmentService.removeServiceAssignment(assignmentId: assignment.id)
            assignments.removeAll { $0.id == assignment.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
