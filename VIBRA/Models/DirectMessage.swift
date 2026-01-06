//
//  DirectMessage.swift
//  VIBRA
//
//  Private message model
//

import Foundation

enum DirectMessageType: String, Codable {
    case text = "text"
    case image = "image"
    case audio = "audio"
}

struct DirectMessage: Identifiable, Codable {
    let id: String
    let conversationId: String
    let senderId: ConversationUser
    let recipientId: String
    let type: String
    let content: String?
    let mediaUrl: String?
    let duration: Int?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case conversationId
        case senderId
        case recipientId
        case type
        case content
        case mediaUrl
        case duration
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        conversationId = try container.decode(String.self, forKey: .conversationId)
        senderId = try container.decode(ConversationUser.self, forKey: .senderId)
        
        // Handle recipientId - can be String or ConversationUser object
        if let recipientIdString = try? container.decode(String.self, forKey: .recipientId) {
            recipientId = recipientIdString
        } else if let recipientUser = try? container.decode(ConversationUser.self, forKey: .recipientId) {
            recipientId = recipientUser.id
        } else {
            recipientId = ""
        }
        
        type = try container.decode(String.self, forKey: .type)
        content = try? container.decode(String.self, forKey: .content)
        mediaUrl = try? container.decode(String.self, forKey: .mediaUrl)
        duration = try? container.decode(Int.self, forKey: .duration)
        
        // Handle date parsing
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            createdAt = formatter.date(from: dateString) ?? Date()
        } else {
            createdAt = Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(conversationId, forKey: .conversationId)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(recipientId, forKey: .recipientId)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(content, forKey: .content)
        try container.encodeIfPresent(mediaUrl, forKey: .mediaUrl)
        try container.encodeIfPresent(duration, forKey: .duration)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
    }
    
    var messageType: DirectMessageType {
        DirectMessageType(rawValue: type) ?? .text
    }
}
