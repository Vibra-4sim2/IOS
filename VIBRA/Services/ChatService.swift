//
//  ChatService.swift
//  VIBRA
//
//  Service réseau pour les messages de chat
//

import Foundation

final class ChatService {
    static let shared = ChatService()
    private init() {}

    private var baseURL: String { Constants.baseURL }

    // MARK: - Helpers

    private func authorizedRequest(url: URL, method: String, jsonBody: [String: Any]? = nil) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = try? KeychainManager.shared.getJWT() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = jsonBody {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        }
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return request
    }

    // MARK: - Messages

    /// GET /messages/sortie/{sortieId}
    func fetchMessages(sortieId: String) async throws -> [ChatMessage] {
        let urlString = "\(baseURL)/messages/sortie/\(sortieId)"
        guard let url = URL(string: urlString) else { throw ParticipationError.badURL }

        let request = try authorizedRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ParticipationError.invalidResponse(-1, "no http response")
        }

        let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
        print("🛰 fetchMessages(\(sortieId)) HTTP \(http.statusCode)")
        print("🧪 RAW JSON:", bodyString.prefix(400), "…")

        guard (200...299).contains(http.statusCode) else {
            throw ParticipationError.invalidResponse(http.statusCode, bodyString)
        }

        // Le backend renvoie { "messages": [ ... ] }
        struct MessagesResponse: Decodable {
            let messages: [ChatMessage]
        }

        do {
            let decoded = try JSONDecoder().decode(MessagesResponse.self, from: data)
            let messages = decoded.messages
            return messages.sorted { ($0.createdDate ?? .distantPast) < ($1.createdDate ?? .distantPast) }
        } catch {
            print("❌ fetchMessages decoding error:", error)
            throw ParticipationError.decoding(error)
        }
    }

    /// POST /messages/sortie/{sortieId}
    /// Pour l’instant: envoi de texte uniquement (type = text)
    func sendTextMessage(sortieId: String, content: String) async throws -> ChatMessage {
        let urlString = "\(baseURL)/messages/sortie/\(sortieId)"
        guard let url = URL(string: urlString) else { throw ParticipationError.badURL }

        let body: [String: Any] = [
            "type": "text",
            "content": content
        ]

        let request = try authorizedRequest(url: url, method: "POST", jsonBody: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ParticipationError.invalidResponse(-1, "no http response")
        }

        let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
        print("🛰 sendTextMessage(\(sortieId)) HTTP \(http.statusCode)")
        print("🧪 RAW JSON:", bodyString.prefix(400), "…")

        guard (200...299).contains(http.statusCode) else {
            throw ParticipationError.invalidResponse(http.statusCode, bodyString)
        }

        do {
            return try JSONDecoder().decode(ChatMessage.self, from: data)
        } catch {
            print("❌ sendTextMessage decoding error:", error)
            throw ParticipationError.decoding(error)
        }
    }
}
