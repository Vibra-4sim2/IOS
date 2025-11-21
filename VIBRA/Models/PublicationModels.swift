//
//  PublicationModels.swift
//  VIBRA
//
//  Created by mac book pro on 11/17/25.
//
import Foundation

// MARK: - Request Models

/// Request pour créer une publication
struct CreatePublicationRequest: Codable {
    let author: String
    let content: String
    let tags: [String]?
    let mentions: [String]?
    let location: String?
}

// MARK: - Response Models

/// Response pour POST /publication (author = String)
struct PublicationCreateResponse: Codable, Identifiable {
    let id: String
    let author: String
    let content: String
    let image: String?
    let tags: [String]?
    let mentions: [String]?
    let location: String?
    let likesCount: Int
    let commentsCount: Int
    let sharesCount: Int
    let likedBy: [String]?
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    let version: Int

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case author
        case content
        case image
        case tags
        case mentions
        case location
        case likesCount
        case commentsCount
        case sharesCount
        case likedBy
        case isActive
        case createdAt
        case updatedAt
        case version = "__v"
    }
}

/// Response pour GET /publication (author = objet complet)
struct PublicationResponse: Codable, Identifiable {
    let id: String
    let author: AuthorData?
    let content: String
    let image: String?
    let tags: [String]?
    let mentions: [MentionData]?
    let location: String?
    let likesCount: Int
    let commentsCount: Int
    let sharesCount: Int
    let likedBy: [String]?
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    let version: Int

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case author
        case content
        case image
        case tags
        case mentions
        case location
        case likesCount
        case commentsCount
        case sharesCount
        case likedBy
        case isActive
        case createdAt
        case updatedAt
        case version = "__v"
    }
}

/// Données de l'auteur (populate)
struct AuthorData: Codable, Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let avatar: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName
        case lastName
        case avatar
    }
}

/// Données d'une mention (populate)
struct MentionData: Codable, Identifiable {
    let id: String
    let firstName: String
    let lastName: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName
        case lastName
    }
}

/// Response d'erreur
struct PublicationErrorResponse: Codable {
    let message: AnyCodable?
    let statusCode: Int?
    let error: String?
}

// Pour message qui peut être String ou [String]
struct AnyCodable: Codable {
    let value: Any?

    init(_ value: Any?) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            value = str
        } else if let arr = try? container.decode([String].self) {
            value = arr
        } else {
            value = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let str = value as? String {
            try container.encode(str)
        } else if let arr = value as? [String] {
            try container.encode(arr)
        } else {
            try container.encodeNil()
        }
    }
}

// MARK: - Helpers

extension AuthorData {
    func fullName() -> String { "\(firstName) \(lastName)" }
}

extension MentionData {
    func fullName() -> String { "\(firstName) \(lastName)" }
}

extension PublicationResponse {
    func hasImage() -> Bool { !(image ?? "").isEmpty }
}

extension AuthorData {
    func avatarOrPlaceholder() -> String {
        avatar?.isEmpty == false ? avatar! : ""
    }
}
