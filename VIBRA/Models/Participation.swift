//
//  Participation.swift
//  VIBRA
//
//  Created by mac book pro on 11/22/25.
//
/*
import Foundation

struct Participation: Codable, Identifiable {
    let id: String?
    let userId: String?
    let sortieId: String?
    let status: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId
        case sortieId
        case status
        case createdAt
        case updatedAt
    }
}

enum ParticipationError: Error, CustomStringConvertible {
    case badURL
    case noToken
    case invalidResponse(Int, String)
    case decoding(Error)
    case network(Error)

    var description: String {
        switch self {
        case .badURL: return "URL invalide"
        case .noToken: return "Token manquant"
        case .invalidResponse(let code, let body): return "Réponse serveur invalide (code: \(code)) body: \(body)"
        case .decoding(let e): return "Erreur de décodage: \(e.localizedDescription)"
        case .network(let e): return "Erreur réseau: \(e.localizedDescription)"
        }
    }
}
*/
import Foundation

// Utilisateur léger dans le champ userId
struct ParticipationUser: Codable, Identifiable {
    let id: String?
    let email: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email
    }
}

// Sortie légère dans le champ sortieId
/// On ne prend que ce qui nous intéresse pour la partie notif
struct ParticipationSortie: Codable, Identifiable {
    let id: String?
    let titre: String?
    let description: String?
    let createurId: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case titre
        case description
        case createurId
    }
}

// Participation conforme au JSON fourni
struct Participation: Codable, Identifiable {
    let id: String?
    let user: ParticipationUser?      // userId objet
    let sortie: ParticipationSortie?  // sortieId objet
    let status: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user = "userId"
        case sortie = "sortieId"
        case status
        case createdAt
        case updatedAt
    }
}

enum ParticipationError: Error, CustomStringConvertible {
    case badURL
    case noToken
    case invalidResponse(Int, String)
    case decoding(Error)
    case network(Error)

    var description: String {
        switch self {
        case .badURL: return "URL invalide"
        case .noToken: return "Token manquant"
        case .invalidResponse(let code, let body): return "Réponse serveur invalide (code: \(code)) body: \(body)"
        case .decoding(let e): return "Erreur de décodage: \(e.localizedDescription)"
        case .network(let e): return "Erreur réseau: \(e.localizedDescription)"
        }
    }
}
