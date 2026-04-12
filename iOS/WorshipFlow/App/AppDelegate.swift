import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

/// Wires the SwiftUI app to UIKit lifecycle callbacks that SwiftUI doesn't expose:
/// Firebase bootstrapping, APNs device-token plumbing, and FCM token forwarding to our backend.
final class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {

    // MARK: - Launch

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        // Ask the system for an APNs token. This does not show a prompt —
        // the prompt is triggered by NotificationService.requestPermission().
        application.registerForRemoteNotifications()

        return true
    }

    // MARK: - APNs token handoff to FCM

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("⚠️ APNs registration failed: \(error.localizedDescription)")
    }

    // MARK: - FCM token

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        print("📲 FCM token: \(fcmToken.prefix(16))…")

        // Only register with backend if we have an authenticated session.
        // (`APIClient` carries the Bearer token; the call is a no-op otherwise.)
        Task { await NotificationService.registerDeviceToken(fcmToken) }
    }

    // MARK: - Foreground presentation

    /// Show banners + play sound even when the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound, .badge])
    }

    /// Invoked when the user taps a notification.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Reserved for deep-link routing in a future iteration.
        completionHandler()
    }
}
