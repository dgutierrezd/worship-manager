import Foundation
import UserNotifications
import FirebaseMessaging

enum NotificationService {
    /// Shows the system push-notification permission prompt (if not yet decided).
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    /// Posts the FCM device token to the backend so the user can receive pushes.
    static func registerDeviceToken(_ token: String) async {
        do {
            let _: MessageResponse = try await APIClient.shared.post(
                "/notifications/register",
                body: ["token": token]
            )
        } catch {
            print("Failed to register device token: \(error)")
        }
    }

    /// Asks FCM for the current registration token and forwards it to the backend.
    /// Call this after sign-in, since the `messaging(_:didReceiveRegistrationToken:)`
    /// delegate may have fired before the user had an auth session.
    static func refreshFCMToken() async {
        do {
            let token = try await Messaging.messaging().token()
            await registerDeviceToken(token)
        } catch {
            print("Failed to fetch FCM token: \(error)")
        }
    }
}
