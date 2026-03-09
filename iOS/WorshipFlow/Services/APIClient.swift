import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(String)
    case decodingError
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .unauthorized: return "Please sign in again."
        case .serverError(let msg): return msg
        case .decodingError: return "Failed to process server response"
        case .networkError(let err): return err.localizedDescription
        }
    }
}

actor APIClient {
    static let shared = APIClient()

    private let baseURL = Config.apiBaseURL
    private var accessToken: String?
    private var refreshToken: String?
    private var isRefreshing = false

    static let accessTokenKey = "worshipflow_access_token"
    static let refreshTokenKey = "worshipflow_refresh_token"

    func setToken(_ token: String?) {
        self.accessToken = token
    }

    func setRefreshToken(_ token: String?) {
        self.refreshToken = token
    }

    func request<T: Decodable>(
        _ method: String,
        path: String,
        body: [String: Any]? = nil
    ) async throws -> T {
        let data = try await rawRequest(method, path: path, body: body, token: accessToken)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }

    /// Executes an HTTP request. On 401, silently refreshes the token and retries once.
    private func rawRequest(
        _ method: String,
        path: String,
        body: [String: Any]? = nil,
        token: String?,
        isRetry: Bool = false
    ) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.serverError("Invalid response")
        }

        // On 401, try to silently refresh and retry once
        if http.statusCode == 401 && !isRetry {
            if let newToken = await silentRefresh() {
                return try await rawRequest(method, path: path, body: body, token: newToken, isRetry: true)
            }
        }

        if http.statusCode >= 400 {
            if let errorBody = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorBody.error)
            }
            if http.statusCode == 401 {
                throw APIError.unauthorized
            }
            throw APIError.serverError("Request failed with status \(http.statusCode)")
        }

        return data
    }

    // MARK: - Silent Token Refresh

    /// Refreshes the access token using the stored refresh token.
    /// Updates both in-memory tokens and UserDefaults.
    private func silentRefresh() async -> String? {
        guard let refreshToken, !isRefreshing else { return nil }
        isRefreshing = true
        defer { isRefreshing = false }

        guard let url = URL(string: "\(baseURL)/auth/refresh") else { return nil }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["refresh_token": refreshToken])

        guard let (data, response) = try? await URLSession.shared.data(for: req),
              let http = response as? HTTPURLResponse,
              http.statusCode == 200 else {
            return nil
        }

        struct RefreshResult: Decodable {
            let session: RefreshSession
        }
        struct RefreshSession: Decodable {
            let accessToken: String
            let refreshToken: String?
            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
                case refreshToken = "refresh_token"
            }
        }

        guard let result = try? JSONDecoder().decode(RefreshResult.self, from: data) else {
            return nil
        }

        // Update in-memory tokens
        self.accessToken = result.session.accessToken
        if let newRefresh = result.session.refreshToken {
            self.refreshToken = newRefresh
        }

        // Persist to UserDefaults (thread-safe)
        UserDefaults.standard.set(result.session.accessToken, forKey: APIClient.accessTokenKey)
        if let newRefresh = result.session.refreshToken {
            UserDefaults.standard.set(newRefresh, forKey: APIClient.refreshTokenKey)
        }

        return result.session.accessToken
    }

    // MARK: - Multipart Upload

    func uploadImage<T: Decodable>(
        _ path: String,
        imageData: Data,
        fieldName: String = "avatar",
        mimeType: String = "image/jpeg"
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        let ext = mimeType == "image/png" ? "png" : "jpg"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"avatar.\(ext)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            if let errorBody = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorBody.error)
            }
            throw APIError.serverError("Upload failed")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Convenience methods

    func get<T: Decodable>(_ path: String) async throws -> T {
        try await request("GET", path: path)
    }

    func post<T: Decodable>(_ path: String, body: [String: Any]? = nil) async throws -> T {
        try await request("POST", path: path, body: body)
    }

    func put<T: Decodable>(_ path: String, body: [String: Any]? = nil) async throws -> T {
        try await request("PUT", path: path, body: body)
    }

    func patch<T: Decodable>(_ path: String, body: [String: Any]? = nil) async throws -> T {
        try await request("PATCH", path: path, body: body)
    }

    func delete(_ path: String) async throws {
        let _: MessageResponse = try await request("DELETE", path: path)
    }
}

struct ErrorResponse: Decodable {
    let error: String
}

struct MessageResponse: Decodable {
    let message: String
}
