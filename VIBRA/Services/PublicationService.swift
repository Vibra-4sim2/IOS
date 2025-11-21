import Foundation
import SwiftUI

final class PublicationService {

    static let shared = PublicationService()

    private let baseURL: URL

    private init() {
        guard let url = URL(string: Constants.baseURL) else {
            fatalError("❌ Constants.baseURL invalide : \(Constants.baseURL)")
        }
        self.baseURL = url
    }

    // MARK: - JWT helpers (utilise le KeychainManager existant)

    private func currentToken() -> String? {
        do {
            let token = try KeychainManager.shared.getJWT()
            return token.isEmpty ? nil : token
        } catch {
            print("🔑 JWT introuvable ou erreur Keychain: \(error)")
            return nil
        }
    }

    private func decodeJWTPayload(_ token: String) -> [String: Any]? {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var payloadB64 = String(parts[1])

        // Padding base64 si nécessaire
        let rem = payloadB64.count % 4
        if rem != 0 {
            payloadB64 += String(repeating: "=", count: 4 - rem)
        }

        guard let data = Data(base64Encoded: payloadB64, options: [.ignoreUnknownCharacters]) else { return nil }
        let obj = try? JSONSerialization.jsonObject(with: data, options: [])
        return obj as? [String: Any]
    }

    private func currentAuthorId() -> String? {
        guard let token = currentToken() else { return nil }
        guard let payload = decodeJWTPayload(token) else {
            print("⚠️ Impossible de décoder le payload JWT.")
            return nil
        }
        // Cherche plusieurs clés possibles
        for key in ["userId", "id", "_id", "sub"] {
            if let val = payload[key] as? String, !val.isEmpty {
                return val
            }
        }
        print("⚠️ Aucun champ userId/id/_id/sub trouvé dans le payload JWT: \(payload)")
        return nil
    }

    private func applyCommonHeaders(to request: inout URLRequest) {
        if let token = currentToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
    }

    // MARK: - GET /publication

    func getAllPublications() async -> Result<[PublicationResponse], Error> {
        do {
            var request = URLRequest(url: baseURL.appendingPathComponent("publication"))
            request.httpMethod = "GET"
            applyCommonHeaders(to: &request)

            print("🌐 GET \(request.url?.absoluteString ?? "")")
            let (data, response) = try await URLSession.shared.data(for: request)
            try validateResponse(response, data: data, expected: [200, 201, 304]) // 304 autorisé
            let decoded = try JSONDecoder().decode([PublicationResponse].self, from: data)
            return .success(decoded)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - POST /publication (multipart)

    func createPublication(
        content: String,
        image: UIImage? = nil,
        tags: [String]? = nil,
        mentions: [String]? = nil,
        location: String? = nil
    ) async -> Result<PublicationResponse, Error> {
        do {
            guard let authorId = currentAuthorId(), !authorId.isEmpty else {
                throw NSError(domain: "PublicationService", code: -10,
                              userInfo: [NSLocalizedDescriptionKey: "Impossible de récupérer l'ID auteur depuis le JWT"])
            }
            var request = URLRequest(url: baseURL.appendingPathComponent("publication"))
            request.httpMethod = "POST"
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            applyCommonHeaders(to: &request)

            print("📤 POST \(request.url?.absoluteString ?? "")")
            print("   author=\(authorId)")
            print("   content=\(content.prefix(80))...")
            print("   tags=\(tags?.joined(separator: ",") ?? "nil")")
            print("   mentions=\(mentions?.joined(separator: ",") ?? "nil")")
            print("   location=\(location ?? "nil")")
            print("   image=\(image != nil ? "YES" : "NO")")

            let body = try createMultipartBody(
                author: authorId,
                content: content,
                image: image,
                tags: tags,
                mentions: mentions,
                location: location,
                boundary: boundary
            )
            request.httpBody = body
            request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")

            let (data, response) = try await URLSession.shared.data(for: request)
            try validateResponse(response, data: data, expected: [201, 200]) // 201 Created attendu

            let decoded = try JSONDecoder().decode(PublicationResponse.self, from: data)
            print("✅ Publication créée: \(decoded.id)")
            return .success(decoded)
        } catch {
            print("❌ Erreur createPublication: \(error)")
            return .failure(error)
        }
    }

    // MARK: - POST /publication/{id}/like

    func likePublication(publicationId: String) async -> Result<PublicationResponse, Error> {
        do {
            guard let authorId = currentAuthorId(), !authorId.isEmpty else {
                throw NSError(domain: "PublicationService", code: -10,
                              userInfo: [NSLocalizedDescriptionKey: "Impossible de récupérer l'ID auteur depuis le JWT"])
            }
            var request = URLRequest(url: baseURL.appendingPathComponent("publication/\(publicationId)/like"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            applyCommonHeaders(to: &request)

            let body = try JSONSerialization.data(withJSONObject: ["userId": authorId], options: [])
            request.httpBody = body
            print("❤️ POST like \(publicationId) userId=\(authorId)")

            let (data, response) = try await URLSession.shared.data(for: request)
            try validateResponse(response, data: data, expected: [200, 201])
            let decoded = try JSONDecoder().decode(PublicationResponse.self, from: data)
            return .success(decoded)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Validation

    private func validateResponse(_ response: URLResponse, data: Data, expected: [Int]) throws {
        guard let http = response as? HTTPURLResponse else { return }
        print("🔎 Status: \(http.statusCode)")

        if (300..<400).contains(http.statusCode) {
            let location = http.allHeaderFields["Location"] as? String
            print("⚠️ Redirect \(http.statusCode) → \(location ?? "no Location")")
            throw NSError(domain: "PublicationService",
                          code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Redirection (\(http.statusCode)). Vérifie Constants.baseURL / HTTPS / chemin."])
        }

        guard expected.contains(http.statusCode) else {
            let message = parseErrorMessage(from: data) ?? "Erreur serveur (\(http.statusCode))"
            throw NSError(domain: "PublicationService",
                          code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: message])
        }
    }

    private func parseErrorMessage(from data: Data) -> String? {
        do {
            let errorResponse = try JSONDecoder().decode(PublicationErrorResponse.self, from: data)
            if let any = errorResponse.message?.value {
                if let str = any as? String { return str }
                if let arr = any as? [String] { return arr.joined(separator: ", ") }
            }
            return errorResponse.error
        } catch {
            return String(data: data, encoding: .utf8)
        }
    }

    // MARK: - Multipart builder

    private func createMultipartBody(
        author: String,
        content: String,
        image: UIImage?,
        tags: [String]?,
        mentions: [String]?,
        location: String?,
        boundary: String
    ) throws -> Data {
        var body = Data()

        func appendField(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        appendField(name: "author", value: author)
        appendField(name: "content", value: content)

        if let tags = tags, !tags.isEmpty {
            appendField(name: "tags", value: tags.joined(separator: ","))
        }
        if let mentions = mentions, !mentions.isEmpty {
            appendField(name: "mentions", value: mentions.joined(separator: ","))
        }
        if let location = location, !location.isEmpty {
            appendField(name: "location", value: location)
        }

        if let image = image, let data = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"upload.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}
