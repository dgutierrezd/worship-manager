import Foundation

struct AuthResponse: Decodable {
    let user: Profile?
    let session: SessionData?
}

struct SessionData: Decodable {
    let accessToken: String
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

enum AuthService {
    static func signUp(email: String, password: String, name: String, instrument: String) async throws -> AuthResponse {
        try await APIClient.shared.post("/auth/signup", body: [
            "email": email,
            "password": password,
            "full_name": name,
            "instrument": instrument
        ])
    }

    static func signIn(email: String, password: String) async throws -> AuthResponse {
        try await APIClient.shared.post("/auth/signin", body: [
            "email": email,
            "password": password
        ])
    }

    static func signOut() async throws {
        try await APIClient.shared.delete("/auth/signout")
    }
}
