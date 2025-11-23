//
//  Chat.swift
//  VIBRA
//
//  Created by mac book pro on 11/23/25.
//
import Foundation
import CoreLocation

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

struct ChatMessage: Codable, Identifiable {
    let id: String
    let chatId: String
    let sortieId: String
    let senderId: String?
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

    var createdDate: Date? {
        guard let createdAt else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return iso.date(from: createdAt)
    }

    var isSystem: Bool { type == .system }
}
struct ChatMember: Codable, Identifiable, Hashable {
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
        let full = "\(firstName ?? "") \(lastName ?? "")".trimmingCharacters(in: .whitespaces)
        return full.isEmpty ? (email ?? "Utilisateur") : full
    }

    var initials: String {
        let f = firstName?.first.map(String.init) ?? ""
        let l = lastName?.first.map(String.init) ?? ""
        let txt = (f + l)
        return txt.isEmpty ? "?" : txt.uppercased()
    }
}
