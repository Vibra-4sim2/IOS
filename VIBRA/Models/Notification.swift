
//
//  Notification.swift
//  VIBRA
//
//  Notification model for HTTP polling
//

import Foundation

struct AppNotification: Identifiable, Codable {
    let id: String
    let title: String
    let body: String
    let type: String
    let data: [String: String]?
    let isRead: Bool
    let createdAt: Date
    let readAt: Date?
    
    // Computed property for time display
    var timeAgo: String {
        let now = Date()
        let interval = now.timeIntervalSince(createdAt)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
    
    // Parse notification type
    var notificationType: NotificationType {
        NotificationType(rawValue: type) ?? .general
    }
}

enum NotificationType: String {
    case general = "general"
    case privateMessage = "private_message"
    case groupMessage = "group_message"
    case newParticipant = "new_participant"
    case sortieUpdate = "sortie_update"
    case sortieReminder = "sortie_reminder"
    case ratingRequest = "rating_request"
}
