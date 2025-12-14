//
//  NotificationItem.swift
//  VIBRA
//
//  Created for polling-based notification system
//

import Foundation

// MARK: - NotificationItem Model
struct NotificationItem: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let body: String
    let type: String
    let data: NotificationData
    let isRead: Bool
    let createdAt: String
    let readAt: String?
    
    static func == (lhs: NotificationItem, rhs: NotificationItem) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - NotificationData
struct NotificationData: Codable {
    let type: String
    let publicationId: String?
    let authorId: String?
    let authorName: String?
    let messageId: String?
    let chatId: String?
    let sortieId: String?
    let senderId: String?
    let senderName: String?
    let chatName: String?
    let rideId: String?
    let rideName: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case publicationId
        case authorId
        case authorName
        case messageId
        case chatId
        case sortieId
        case senderId
        case senderName
        case chatName
        case rideId
        case rideName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        publicationId = try? container.decode(String.self, forKey: .publicationId)
        authorId = try? container.decode(String.self, forKey: .authorId)
        authorName = try? container.decode(String.self, forKey: .authorName)
        messageId = try? container.decode(String.self, forKey: .messageId)
        chatId = try? container.decode(String.self, forKey: .chatId)
        sortieId = try? container.decode(String.self, forKey: .sortieId)
        senderId = try? container.decode(String.self, forKey: .senderId)
        senderName = try? container.decode(String.self, forKey: .senderName)
        chatName = try? container.decode(String.self, forKey: .chatName)
        rideId = try? container.decode(String.self, forKey: .rideId)
        rideName = try? container.decode(String.self, forKey: .rideName)
    }
    
    // Convert to dictionary for userInfo
    func toDictionary() -> [String: String] {
        var dict: [String: String] = ["type": type]
        if let publicationId = publicationId { dict["publicationId"] = publicationId }
        if let authorId = authorId { dict["authorId"] = authorId }
        if let authorName = authorName { dict["authorName"] = authorName }
        if let messageId = messageId { dict["messageId"] = messageId }
        if let chatId = chatId { dict["chatId"] = chatId }
        if let sortieId = sortieId { dict["sortieId"] = sortieId }
        if let senderId = senderId { dict["senderId"] = senderId }
        if let senderName = senderName { dict["senderName"] = senderName }
        if let chatName = chatName { dict["chatName"] = chatName }
        if let rideId = rideId { dict["rideId"] = rideId }
        if let rideName = rideName { dict["rideName"] = rideName }
        return dict
    }
}

// MARK: - BadgeResponse
struct BadgeResponse: Codable {
    let count: Int
}

// MARK: - MarkAsReadResponse
struct MarkAsReadResponse: Codable {
    let success: Bool
    let message: String
}
