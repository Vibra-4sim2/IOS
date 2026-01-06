//
//  Conversation.swift
//  VIBRA
//
//  Private messaging conversation model
//

import Foundation

struct Conversation: Identifiable, Codable {
    let id: String
    let conversationId: String
    let otherUser: ConversationUser
    let lastMessage: DirectMessage?
    let unreadCount: Int
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case conversationId
        case otherUser
        case lastMessage
        case unreadCount
        case updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        conversationId = try container.decode(String.self, forKey: .conversationId)
        otherUser = try container.decode(ConversationUser.self, forKey: .otherUser)
        lastMessage = try? container.decode(DirectMessage.self, forKey: .lastMessage)
        unreadCount = try container.decodeIfPresent(Int.self, forKey: .unreadCount) ?? 0
        
        // Handle date parsing
        if let dateString = try? container.decode(String.self, forKey: .updatedAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            updatedAt = formatter.date(from: dateString) ?? Date()
        } else {
            updatedAt = Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(conversationId, forKey: .conversationId)
        try container.encode(otherUser, forKey: .otherUser)
        try container.encodeIfPresent(lastMessage, forKey: .lastMessage)
        try container.encode(unreadCount, forKey: .unreadCount)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: updatedAt), forKey: .updatedAt)
    }
}
