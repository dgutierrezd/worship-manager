import Foundation

/// One row of the attendance roster for a service or rehearsal.
/// The backend returns the user's profile via a Postgres join, which
/// Supabase serialises under the `profiles` key.
struct AttendanceRSVP: Codable, Identifiable {
    let userId: String
    let status: String
    let updatedAt: String?
    let profile: ProfileRef?

    var id: String { userId }

    enum CodingKeys: String, CodingKey {
        case status
        case userId    = "user_id"
        case updatedAt = "updated_at"
        case profile   = "profiles"
    }

    struct ProfileRef: Codable {
        let fullName: String?
        let avatarUrl: String?
        let instrument: String?

        enum CodingKeys: String, CodingKey {
            case fullName   = "full_name"
            case avatarUrl  = "avatar_url"
            case instrument
        }
    }

    /// Display name fallback chain: profile.fullName → "Member".
    var displayName: String {
        profile?.fullName?.trimmingCharacters(in: .whitespaces).nonEmpty ?? "Member"
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
