//
//  NotificationViewModel.swift
//  VIBRA
//
//  ViewModel for notification polling and management
//

import Foundation
import Combine

@MainActor
final class NotificationViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var pollingTimer: Timer?
    private let pollingInterval: TimeInterval = 10 // Poll every 10 seconds

    // Track shown notification IDs to avoid duplicate banners
    private var shownNotificationIds: Set<String> = []

    // Computed property for badge display
    var hasUnreadNotifications: Bool {
        unreadCount > 0
    }

    init() {
        startPolling()
    }

    deinit {
        // Cannot call @MainActor methods from deinit, so directly invalidate timer
        pollingTimer?.invalidate()
    }

    // MARK: - Polling

    func startPolling() {
        // Check if user is authenticated before starting polling
        guard (try? KeychainManager.shared.getJWT()) != nil else {
            print("⚠️ NotificationViewModel: No token, skipping polling")
            return
        }

        // Initial fetch
        Task {
            await fetchNotifications()
            await fetchUnreadCount()
        }

        // Start timer for periodic polling
        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                // Check token on each poll
                guard (try? KeychainManager.shared.getJWT()) != nil else {
                    self?.stopPolling()
                    return
                }
                await self?.fetchUnreadCount()
            }
        }
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    // MARK: - Fetch Notifications

    func fetchNotifications() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedNotifications = try await NotificationService.shared.getNotifications(
                unreadOnly: false,
                limit: 50,
                offset: 0
            )
            notifications = fetchedNotifications
            print("✅ Fetched \(notifications.count) notifications")
        } catch {
            errorMessage = "Failed to load notifications"
            print("❌ Fetch notifications error: \(error)")
        }

        isLoading = false
    }

    // MARK: - Fetch Unread Count

    func fetchUnreadCount() async {
        do {
            let count = try await NotificationService.shared.getUnreadCount()

            // Check if there are NEW notifications (count increased)
            let hadNewNotifications = count > unreadCount

            unreadCount = count
            print("📬 Unread count: \(count)")

            // Update app badge
            LocalNotificationManager.shared.updateBadge(count: count)

            // If new notifications arrived, fetch details and show local notification
            if hadNewNotifications {
                await fetchAndShowNewNotifications()
            }
        } catch {
            print("❌ Fetch unread count error: \(error)")
        }
    }

    // MARK: - Fetch and Show New Notifications

    private func fetchAndShowNewNotifications() async {
        do {
            let latestNotifications = try await NotificationService.shared.getNotifications(
                unreadOnly: true,
                limit: 10, // fetch up to 10 at a time
                offset: 0
            )
            // Show local notification for each unread notification not already shown
            for notif in latestNotifications where !notif.isRead && !shownNotificationIds.contains(notif.id) {
                LocalNotificationManager.shared.showNotification(
                    title: notif.title,
                    body: notif.body,
                    identifier: notif.id,
                    badge: unreadCount,
                    userInfo: [
                        "type": notif.type,
                        "notificationId": notif.id,
                        "data": notif.data ?? [:]
                    ]
                )
                shownNotificationIds.insert(notif.id)
            }
        } catch {
            print("❌ Failed to fetch new notifications: \(error)")
        }
    }

    // MARK: - Mark as Read

    func markAsRead(notificationId: String) async {
        do {
            try await NotificationService.shared.markAsRead(notificationId: notificationId)

            // Update local state
            if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
                var updatedNotification = notifications[index]
                notifications[index] = AppNotification(
                    id: updatedNotification.id,
                    title: updatedNotification.title,
                    body: updatedNotification.body,
                    type: updatedNotification.type,
                    data: updatedNotification.data,
                    isRead: true,
                    createdAt: updatedNotification.createdAt,
                    readAt: Date()
                )
            }

            // Update unread count and badge
            await fetchUnreadCount()

            print("✅ Marked notification \(notificationId) as read")
        } catch {
            print("❌ Mark as read error: \(error)")
        }
    }

    // MARK: - Mark All as Read

    func markAllAsRead() async {
        let unreadIds = notifications.filter { !$0.isRead }.map { $0.id }
        guard !unreadIds.isEmpty else { return }
        do {
            try await NotificationService.shared.markAllAsRead(notificationIds: unreadIds)

            // Update local state
            notifications = notifications.map { notification in
                AppNotification(
                    id: notification.id,
                    title: notification.title,
                    body: notification.body,
                    type: notification.type,
                    data: notification.data,
                    isRead: true,
                    createdAt: notification.createdAt,
                    readAt: Date()
                )
            }
            unreadCount = 0

            // Clear app badge
            LocalNotificationManager.shared.clearBadge()

            // Clear shown notification tracking so banners can show for new notifications
            shownNotificationIds.removeAll()

            print("✅ Marked all notifications as read")
        } catch {
            print("❌ Mark all as read error: \(error)")
        }
    }

    // MARK: - Handle Notification Tap

    func handleNotificationTap(_ notification: AppNotification) {
        // Mark as read when tapped
        Task {
            await markAsRead(notificationId: notification.id)
        }

        // Handle navigation based on notification type
        // This will be handled in the view layer with NavigationLink
    }
}
