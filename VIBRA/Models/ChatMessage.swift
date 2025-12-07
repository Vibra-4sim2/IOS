//
//  ChatMessage.swift
//  VIBRA
//
//  Modèle Swift pour les messages de chat
//

import Foundation

enum ChatMessageType: String, Codable, CaseIterable {
    case text = "text"
    case image = "image"
    case video = "video"
    case audio = "audio"      // Message vocal
    case file = "file"
    case system = "system"
    case poll = "poll"
    
    var displayName: String {
        switch self {
        case .text: return "Texte"
        case .image: return "Image"
        case .video: return "Vidéo"
        case .audio: return "Message vocal"
        case .file: return "Fichier"
        case .system: return "Système"
        case .poll: return "Sondage"
        }
    }
    
    var icon: String {
        switch self {
        case .text: return "text.bubble"
        case .image: return "photo"
        case .video: return "video"
        case .audio: return "waveform"
        case .file: return "doc"
        case .system: return "info.circle"
        case .poll: return "chart.bar.xaxis"
        }
    }
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
    let poll: Poll?

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
        case poll
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
        self.poll = try container.decodeIfPresent(Poll.self, forKey: .poll)
    }

    var createdDate: Date? {
        guard let createdAt else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return iso.date(from: createdAt)
    }

    var isSystem: Bool { type == .system }
    
    // Helper pour créer un message de poll ou mettre à jour le poll d'un message existant
    func withUpdatedPoll(_ newPoll: Poll) -> ChatMessage {
        return ChatMessage(
            id: self.id,
            chatId: self.chatId,
            sortieId: self.sortieId,
            senderId: self.senderId,
            sender: self.sender,
            type: .poll,
            content: self.content,
            mediaUrl: self.mediaUrl,
            thumbnailUrl: self.thumbnailUrl,
            mediaDuration: self.mediaDuration,
            fileSize: self.fileSize,
            fileName: self.fileName,
            mimeType: self.mimeType,
            location: self.location,
            readBy: self.readBy,
            isDeleted: self.isDeleted,
            replyTo: self.replyTo,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt,
            poll: newPoll
        )
    }
    
    // Initializer pour créer un message de poll depuis un Poll
    static func createPollMessage(from poll: Poll, sender: ChatUser?) -> ChatMessage {
        let now = ISO8601DateFormatter().string(from: Date())
        return ChatMessage(
            id: UUID().uuidString, // Temporary ID
            chatId: poll.chatId,
            sortieId: "", // Will be filled when received
            senderId: poll.creatorId,
            sender: sender,
            type: .poll,
            content: poll.question,
            mediaUrl: nil,
            thumbnailUrl: nil,
            mediaDuration: nil,
            fileSize: nil,
            fileName: nil,
            mimeType: nil,
            location: nil,
            readBy: [],
            isDeleted: false,
            replyTo: nil,
            createdAt: poll.createdAt ?? now,
            updatedAt: poll.updatedAt ?? now,
            poll: poll
        )
    }
    
    // Public initializer
    init(
        id: String,
        chatId: String,
        sortieId: String,
        senderId: String?,
        sender: ChatUser?,
        type: ChatMessageType,
        content: String?,
        mediaUrl: String?,
        thumbnailUrl: String?,
        mediaDuration: Double?,
        fileSize: Int?,
        fileName: String?,
        mimeType: String?,
        location: ChatLocation?,
        readBy: [String],
        isDeleted: Bool,
        replyTo: String?,
        createdAt: String?,
        updatedAt: String?,
        poll: Poll?
    ) {
        self.id = id
        self.chatId = chatId
        self.sortieId = sortieId
        self.senderId = senderId
        self.sender = sender
        self.type = type
        self.content = content
        self.mediaUrl = mediaUrl
        self.thumbnailUrl = thumbnailUrl
        self.mediaDuration = mediaDuration
        self.fileSize = fileSize
        self.fileName = fileName
        self.mimeType = mimeType
        self.location = location
        self.readBy = readBy
        self.isDeleted = isDeleted
        self.replyTo = replyTo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.poll = poll
    }
}
