//
//  NotificationsView.swift
//  VIBRA
//
//  Notifications list view with HTTP polling
//

import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.BackgroundDark
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.GreenAccent))
                } else if viewModel.notifications.isEmpty {
                    emptyStateView
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.unreadCount > 0 {
                        Button("Mark All Read") {
                            Task {
                                await viewModel.markAllAsRead()
                            }
                        }
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.GreenAccent)
                    }
                }
            }
            .refreshable {
                await viewModel.fetchNotifications()
            }
            .onAppear {
                Task {
                    await viewModel.fetchNotifications()
                }
            }
        }
    }
    
    // MARK: - Notifications List
    
    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.notifications) { notification in
                    NotificationRow(notification: notification) {
                        viewModel.handleNotificationTap(notification)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(AppColors.TextTertiary)
            
            Text("No Notifications")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppColors.TextPrimary)
            
            Text("You're all caught up!")
                .font(.system(size: 15))
                .foregroundColor(AppColors.TextSecondary)
        }
        .padding()
    }
}

// MARK: - Notification Row

struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                notificationIcon
                    .frame(width: 40, height: 40)
                    .background(iconBackgroundColor)
                    .clipShape(Circle())
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.TextPrimary)
                        .lineLimit(2)
                    
                    Text(notification.body)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.TextSecondary)
                        .lineLimit(3)
                    
                    Text(notification.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.TextTertiary)
                        .padding(.top, 2)
                }
                
                Spacer()
                
                // Unread indicator
                if !notification.isRead {
                    Circle()
                        .fill(AppColors.GreenAccent)
                        .frame(width: 10, height: 10)
                        .padding(.top, 4)
                }
            }
            .padding(12)
            .background(notification.isRead ? AppColors.CardDark : AppColors.CardDark.opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(notification.isRead ? Color.clear : AppColors.GreenAccent.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Notification Icon
    
    private var notificationIcon: some View {
        Group {
            switch notification.notificationType {
            case .privateMessage:
                Image(systemName: "message.fill")
                    .foregroundColor(.blue)
            case .groupMessage:
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.purple)
            case .newParticipant:
                Image(systemName: "person.badge.plus.fill")
                    .foregroundColor(.green)
            case .sortieUpdate:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
            case .sortieReminder:
                Image(systemName: "bell.fill")
                    .foregroundColor(.yellow)
            case .ratingRequest:
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            case .general:
                Image(systemName: "bell.fill")
                    .foregroundColor(AppColors.GreenAccent)
            }
        }
        .font(.system(size: 20))
    }
    
    private var iconBackgroundColor: Color {
        switch notification.notificationType {
        case .privateMessage:
            return Color.blue.opacity(0.2)
        case .groupMessage:
            return Color.purple.opacity(0.2)
        case .newParticipant:
            return Color.green.opacity(0.2)
        case .sortieUpdate:
            return Color.orange.opacity(0.2)
        case .sortieReminder:
            return Color.yellow.opacity(0.2)
        case .ratingRequest:
            return Color.yellow.opacity(0.2)
        case .general:
            return AppColors.GreenAccent.opacity(0.2)
        }
    }
}

#Preview {
    NotificationsView()
}
