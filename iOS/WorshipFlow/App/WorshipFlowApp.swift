import SwiftUI

@main
struct WorshipFlowApp: App {
    // Bridges UIKit-only callbacks (Firebase init, APNs token, FCM delegate)
    // into this otherwise pure-SwiftUI app.
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var authVM = AuthViewModel()
    @ObservedObject private var langManager = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
                .id(langManager.currentLanguage)
                .preferredColorScheme(.light)
                // Request push permission once the user is signed in and tokens exist.
                .onChange(of: authVM.isAuthenticated) { _, isAuthed in
                    guard isAuthed else { return }
                    Task {
                        let granted = await NotificationService.requestPermission()
                        print("🔔 Notification permission granted: \(granted)")
                        // Re-request the FCM token so the delegate fires and we post
                        // the token to the backend now that we have an auth session.
                        if granted {
                            await NotificationService.refreshFCMToken()
                        }
                    }
                }
        }
    }
}
