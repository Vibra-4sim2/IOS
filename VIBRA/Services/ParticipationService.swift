//  ParticipationService.swift
//  VIBRA
//
//  Created to handle user participation in a sortie.
//

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

final class ParticipationService {
    static let shared = ParticipationService()
    private init() {}

    private var baseURL: String { Constants.baseURL }

    // Créer une participation. Le backend peut inférer userId via le JWT; on envoie aussi userId si accepté.
    func createParticipation(userId: String, sortieId: String) async throws -> Participation {
        let urlString = "\(baseURL)/participations"
        guard let url = URL(string: urlString) else { throw ParticipationError.badURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Récupération token
        guard let token = try? KeychainManager.shared.getJWT() else { throw ParticipationError.noToken }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Corps: envoyer sortieId (et userId si backend le tolère)
        let body: [String: Any] = [
            "sortieId": sortieId,
            "userId": userId, // Optionnel côté backend si il lit le JWT
            "status": "EN_ATTENTE"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw ParticipationError.invalidResponse(-1, "no http response") }
            let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
            guard (200...299).contains(http.statusCode) else {
                throw ParticipationError.invalidResponse(http.statusCode, bodyString)
            }
            do {
                return try JSONDecoder().decode(Participation.self, from: data)
            } catch {
                throw ParticipationError.decoding(error)
            }
        } catch {
            throw ParticipationError.network(error)
        }
    }

    // (Optionnel) Récupérer les participations pour une sortie
    func listParticipations(sortieId: String) async throws -> [Participation] {
        guard let url = URL(string: "\(baseURL)/participations/sortie/\(sortieId)") else { throw ParticipationError.badURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = try? KeychainManager.shared.getJWT() { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ParticipationError.invalidResponse(-1, "no http response") }
        let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
        guard (200...299).contains(http.statusCode) else { throw ParticipationError.invalidResponse(http.statusCode, bodyString) }
        do { return try JSONDecoder().decode([Participation].self, from: data) } catch { throw ParticipationError.decoding(error) }
    }
}
