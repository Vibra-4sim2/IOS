//
//  ChatMessage.swift
//  VIBRA
//
//  Modèle Swift pour les messages de chat
//

import Foundation

enum ChatMessageType: String, Codable {
    case text = "text"
    case image = "image"
    case video = "video"
    case audio = "audio"
    case file = "file"
    case location = "location"
    case system = "system"
}

struct ChatLocation: Codable {
    let latitude: Double
    let longitude: Double
    let address: String?
    let name: String?
}

// Représente un user envoyé dans senderId
struct ChatUser: Codable, Equatable {
    let id: String
    let firstName: String?
    let lastName: String?
    let email: String?
    let avatar: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName
        case lastName
        case email
        case avatar
    }

    var displayName: String {
        [firstName, lastName]
            .compactMap { $0 }
            .joined(separator: " ")
    }
}

// DTO interne pour gérer senderId string OU objet user complet
private struct SenderRef: Decodable {
    let id: String?
    let user: ChatUser?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // 1) Essayer comme string simple (id seul)
        if let str = try? container.decode(String.self) {
            self.id = str
            self.user = nil
            return
        }

        // 2) Essayer comme objet user complet
        if let obj = try? container.decode(ChatUser.self) {
            self.id = obj.id
            self.user = obj
            return
        }

        // 3) Null / autre format : on met nil
        self.id = nil
        self.user = nil
    }
}

struct ChatMessage: Identifiable, Decodable {
    let id: String
    let chatId: String
    let sortieId: String
    let senderId: String?        // id du user
    let sender: ChatUser?        // infos complètes du user (nom + avatar)
    let type: ChatMessageType
    let content: String?
    let mediaUrl: String?
    let thumbnailUrl: String?
    let mediaDuration: Double?
    let fileSize: Int?
    let fileName: String?
    let mimeType: String?
    let location: ChatLocation?
    let readBy: [String]
    let isDeleted: Bool
    let replyTo: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case chatId
        case sortieId
        case senderId
        case type
        case content
        case mediaUrl
        case thumbnailUrl
        case mediaDuration
        case fileSize
        case fileName
        case mimeType
        case location
        case readBy
        case isDeleted
        case replyTo
        case createdAt
        case updatedAt
    }

    // Décodage personnalisé pour utiliser SenderRef
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.chatId = try container.decode(String.self, forKey: .chatId)
        self.sortieId = try container.decode(String.self, forKey: .sortieId)

        if let senderRef = try? container.decodeIfPresent(SenderRef.self, forKey: .senderId) {
            self.senderId = senderRef.id
            self.sender = senderRef.user
        } else {
            self.senderId = nil
            self.sender = nil
        }

        self.type = try container.decode(ChatMessageType.self, forKey: .type)
        self.content = try container.decodeIfPresent(String.self, forKey: .content)
        self.mediaUrl = try container.decodeIfPresent(String.self, forKey: .mediaUrl)
        self.thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        self.mediaDuration = try container.decodeIfPresent(Double.self, forKey: .mediaDuration)
        self.fileSize = try container.decodeIfPresent(Int.self, forKey: .fileSize)
        self.fileName = try container.decodeIfPresent(String.self, forKey: .fileName)
        self.mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType)
        self.location = try container.decodeIfPresent(ChatLocation.self, forKey: .location)
        self.readBy = try container.decodeIfPresent([String].self, forKey: .readBy) ?? []
        self.isDeleted = try container.decodeIfPresent(Bool.self, forKey: .isDeleted) ?? false
        self.replyTo = try container.decodeIfPresent(String.self, forKey: .replyTo)
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }

    var createdDate: Date? {
        guard let createdAt else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return iso.date(from: createdAt)
    }

    var isSystem: Bool { type == .system }
}
