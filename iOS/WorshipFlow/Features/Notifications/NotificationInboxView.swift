import SwiftUI

// MARK: - Notification Inbox View
//
// Lists every notification the current user has received. Tapping a row
// marks it read and routes the user to the corresponding service or
// rehearsal detail screen via `DeepLinkRouter`.

struct NotificationInboxView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = NotificationInboxViewModel()

    var body: some View {
        NavigationStack {
            content
                .background(Color.appBackground)
                .navigationTitle("notifications".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("done".localized) { dismiss() }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            Task { await vm.markAllRead() }
                        } label: {
                            Text("mark_all_read".localized)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .disabled(vm.unreadCount == 0)
                    }
                }
                .task { await vm.load() }
                .refreshable { await vm.load() }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if vm.isLoading && vm.notifications.isEmpty {
            List {
                ForEach(0..<6, id: \.self) { _ in
                    SkeletonNotificationRow()
                        .listRowBackground(Color.appSurface)
                        .listRowSeparatorTint(Color.appDivider)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .allowsHitTesting(false)
        } else if vm.notifications.isEmpty {
            EmptyStateView(
                icon: "🔔",
                title: "no_notifications_title".localized,
                subtitle: "no_notifications_subtitle".localized
            )
        } else {
            List {
                ForEach(vm.notifications) { n in
                    Button {
                        handleTap(n)
                    } label: {
                        NotificationRow(notification: n)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(n.isRead ? Color.appSurface : Color.appAccent.opacity(0.06))
                    .listRowSeparatorTint(Color.appDivider)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: - Row tap

    /// Marks the notification read and, if it carries a deep-link target,
    /// forwards the route to the shared router and dismisses the sheet.
    private func handleTap(_ n: AppNotification) {
        AppHaptics.selection()
        Task { await vm.markRead(n) }

        if n.entityId != nil, n.kind != "system" {
            DeepLinkRouter.shared.handle(notification: n)
            dismiss()
        }
    }
}

// MARK: - Row

private struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon tile
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconBg.opacity(0.16))
                    .frame(width: 40, height: 40)
                Image(systemName: notification.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconBg)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(notification.title)
                        .font(.appHeadline)
                        .foregroundColor(.appPrimary)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    Text(notification.relativeTime)
                        .font(.appSmall)
                        .foregroundColor(.appSecondary)
                        .lineLimit(1)
                }

                Text(notification.body)
                    .font(.appCaption)
                    .foregroundColor(.appSecondary)
                    .lineLimit(3)
            }

            if !notification.isRead {
                Circle()
                    .fill(Color.appAccent)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private var iconBg: Color {
        switch notification.kind {
        case "service":   return .featureServices
        case "rehearsal": return .featureSchedule
        default:          return .appAccent
        }
    }
}

// MARK: - Skeleton Row

private struct SkeletonNotificationRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SkeletonBlock(width: 40, height: 40, cornerRadius: 10)
            VStack(alignment: .leading, spacing: 8) {
                SkeletonBlock(height: 14, cornerRadius: 4)
                SkeletonBlock(width: 220, height: 10, cornerRadius: 4)
                SkeletonBlock(width: 160, height: 10, cornerRadius: 4)
            }
        }
        .padding(.vertical, 6)
    }
}
