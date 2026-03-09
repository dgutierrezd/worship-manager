import Foundation
import UserNotifications

enum NotificationService {
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

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
}
