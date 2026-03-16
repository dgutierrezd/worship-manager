import Foundation

enum ServiceAssignmentService {

    // MARK: - Service Assignments

    static func getServiceAssignments(setlistId: String) async throws -> [ServiceAssignment] {
        try await APIClient.shared.get("/setlists/\(setlistId)/assignments")
    }

    static func addServiceAssignment(
        setlistId: String,
        userId: String,
        role: String,
        instrument: String?,
        notes: String?
    ) async throws -> ServiceAssignment {
        var body: [String: Any] = ["user_id": userId, "role": role]
        if let instrument, !instrument.isEmpty { body["instrument"] = instrument }
        if let notes, !notes.isEmpty           { body["notes"] = notes }
        return try await APIClient.shared.post("/setlists/\(setlistId)/assignments", body: body)
    }

    static func updateServiceAssignment(
        assignmentId: String,
        role: String?,
        status: String?,
        instrument: String?
    ) async throws -> ServiceAssignment {
        var body: [String: Any] = [:]
        if let role       { body["role"] = role }
        if let status     { body["status"] = status }
        if let instrument { body["instrument"] = instrument }
        return try await APIClient.shared.put("/assignments/\(assignmentId)", body: body)
    }

    static func removeServiceAssignment(assignmentId: String) async throws {
        try await APIClient.shared.delete("/assignments/\(assignmentId)")
    }

    // MARK: - Respond to assignment (member self-response)

    static func respondToAssignment(assignmentId: String, status: String) async throws -> ServiceAssignment {
        try await APIClient.shared.patch("/assignments/\(assignmentId)/respond", body: ["status": status])
    }
}
