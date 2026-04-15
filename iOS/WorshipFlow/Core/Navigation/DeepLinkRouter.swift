import SwiftUI

/// A pending in-app route requested by a push-notification tap or
/// inbox-row tap. Read by `BandHomeView` (the visible host of services
/// and rehearsals) which navigates accordingly.
enum DeepLinkRoute: Equatable {
    case service(id: String)
    case rehearsal(id: String)
}

/// Singleton router used to bridge UIKit-only callbacks (notification
/// tap, AppDelegate methods) into the SwiftUI view hierarchy.
///
/// `pendingRoute` is set from anywhere; the home view observes it via
/// `@ObservedObject` and consumes (clears) it after navigating.
@MainActor
final class DeepLinkRouter: ObservableObject {
    static let shared = DeepLinkRouter()
    private init() {}

    @Published var pendingRoute: DeepLinkRoute?

    /// Decodes the FCM `data` payload sent by the backend.
    /// Expected keys: `kind` ("service" | "rehearsal") + `entity_id` (UUID).
    func handle(payload: [AnyHashable: Any]) {
        let kind = (payload["kind"] as? String)
                ?? (payload["gcm.notification.kind"] as? String)
        let entityId = (payload["entity_id"] as? String)
                    ?? (payload["gcm.notification.entity_id"] as? String)

        guard let kind, let entityId else { return }

        switch kind {
        case "service":   pendingRoute = .service(id: entityId)
        case "rehearsal": pendingRoute = .rehearsal(id: entityId)
        default:          break
        }
    }

    /// Called by the inbox screen.
    func handle(notification: AppNotification) {
        guard let entityId = notification.entityId else { return }
        switch notification.kind {
        case "service":   pendingRoute = .service(id: entityId)
        case "rehearsal": pendingRoute = .rehearsal(id: entityId)
        default:          break
        }
    }

    /// Called by the destination view once it has consumed the route.
    func clear() { pendingRoute = nil }
}
