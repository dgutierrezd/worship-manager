import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var profile: Profile?

    private let tokenKey = APIClient.accessTokenKey
    private let refreshTokenKey = APIClient.refreshTokenKey

    init() {
        let accessToken = UserDefaults.standard.string(forKey: tokenKey)
        let refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey)

        if accessToken != nil || refreshToken != nil {
            Task {
                if let at = accessToken {
                    await APIClient.shared.setToken(at)
                }
                if let rt = refreshToken {
                    await APIClient.shared.setRefreshToken(rt)
                }
                // Tokens are set on APIClient BEFORE we flip isAuthenticated
                isAuthenticated = true
            }
        }
    }

    func signUp(email: String, password: String, name: String, instrument: String) async {
        isLoading = true
        error = nil

        do {
            let response = try await AuthService.signUp(
                email: email, password: password, name: name, instrument: instrument
            )
            await handleAuthResponse(response)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil

        do {
            let response = try await AuthService.signIn(email: email, password: password)
            await handleAuthResponse(response)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func signOut() async {
        try? await AuthService.signOut()
        await APIClient.shared.setToken(nil)
        await APIClient.shared.setRefreshToken(nil)
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        isAuthenticated = false
        profile = nil
    }

    /// Sets tokens on the APIClient and persists them BEFORE flipping isAuthenticated
    private func handleAuthResponse(_ response: AuthResponse) async {
        if let session = response.session {
            // Persist to UserDefaults
            UserDefaults.standard.set(session.accessToken, forKey: tokenKey)
            if let rt = session.refreshToken {
                UserDefaults.standard.set(rt, forKey: refreshTokenKey)
            }

            // Await setting tokens on APIClient so they're ready before any API call
            await APIClient.shared.setToken(session.accessToken)
            if let rt = session.refreshToken {
                await APIClient.shared.setRefreshToken(rt)
            }
        }
        profile = response.user
        // NOW flip auth state — tokens are guaranteed to be set
        isAuthenticated = true
    }
}
