import Foundation

// MARK: - Notification Inbox ViewModel
//
// Owns the list of in-app notifications (`AppNotification`) plus the
// unread badge count used by the home-screen bell icon. All REST calls
// go through `NotificationInboxService`.

@MainActor
final class NotificationInboxViewModel: ObservableObject {

    // MARK: - Published state

    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Loading

    /// Fetches the full inbox (newest first) and the unread count in parallel.
    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            async let list  = NotificationInboxService.list()
            async let count = NotificationInboxService.unreadCount()
            self.notifications = try await list
            self.unreadCount   = try await count
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Lightweight refresh of just the unread count — used by the
    /// home-screen bell badge on app foreground / tab switches.
    func refreshUnreadCount() async {
        do {
            self.unreadCount = try await NotificationInboxService.unreadCount()
        } catch {
            // Non-fatal — the badge is cosmetic.
        }
    }

    // MARK: - Mutations

    /// Marks a single notification as read, optimistically updating the
    /// local list and unread count so the UI reacts immediately.
    func markRead(_ notification: AppNotification) async {
        guard !notification.isRead else { return }

        // Optimistic local update
        if let idx = notifications.firstIndex(where: { $0.id == notification.id }) {
            let now = ISO8601DateFormatter().string(from: Date())
            var copy = notifications[idx]
            copy = AppNotification(
                id: copy.id,
                userId: copy.userId,
                bandId: copy.bandId,
                kind: copy.kind,
                title: copy.title,
                body: copy.body,
                entityId: copy.entityId,
                readAt: now,
                createdAt: copy.createdAt
            )
            notifications[idx] = copy
        }
        unreadCount = max(0, unreadCount - 1)

        do {
            try await NotificationInboxService.markRead(id: notification.id)
        } catch {
            // Refresh on failure to reconcile truth.
            await load()
        }
    }

    /// Marks every unread notification as read.
    func markAllRead() async {
        guard unreadCount > 0 else { return }

        let now = ISO8601DateFormatter().string(from: Date())
        notifications = notifications.map { n in
            n.isRead ? n : AppNotification(
                id: n.id, userId: n.userId, bandId: n.bandId,
                kind: n.kind, title: n.title, body: n.body,
                entityId: n.entityId, readAt: now, createdAt: n.createdAt
            )
        }
        unreadCount = 0

        do {
            try await NotificationInboxService.markAllRead()
        } catch {
            await load()
        }
    }
}
