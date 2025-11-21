import Foundation
import SwiftUI

/// Service réseau + logique métier (équivalent PublicationApiService + PublicationRepository)
final class PublicationService {

    static let shared = PublicationService()

    // Utilisation de la baseURL définie dans Constants
    private let baseURL: URL

    private init() {
        guard let url = URL(string: Constants.baseURL) else {
            fatalError("❌ Constants.baseURL invalide : \(Constants.baseURL)")
        }
        self.baseURL = url
    }

    // MARK: - Helpers userId (équivalent UserPreferences.getUserId)

    private func currentUserId() -> String? {
        UserDefaults.standard.string(forKey: "userId")
    }

    // MARK: - GET /publication

    func getAllPublications() async -> Result<[PublicationResponse], Error> {
        do {
            let url = baseURL.appendingPathComponent("publication")
            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            let (data, response) = try await URLSession.shared.data(for: request)
            try validateResponse(response, data: data)

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
            guard let userId = currentUserId(), !userId.isEmpty else {
                throw NSError(
                    domain: "PublicationService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "User not logged in"]
                )
            }

            let url = baseURL.appendingPathComponent("publication")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            let body = try createMultipartBody(
                author: userId,
                content: content,
                image: image,
                tags: tags,
                mentions: mentions,
                location: location,
                boundary: boundary
            )
            request.httpBody = body

            let (data, response) = try await URLSession.shared.data(for: request)
            try validateResponse(response, data: data)

            let decoded = try JSONDecoder().decode(PublicationResponse.self, from: data)
            return .success(decoded)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - POST /publication/{id}/like

    func likePublication(publicationId: String) async -> Result<PublicationResponse, Error> {
        do {
            guard let userId = currentUserId(), !userId.isEmpty else {
                throw NSError(
                    domain: "PublicationService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "User not logged in"]
                )
            }

            let url = baseURL.appendingPathComponent("publication/\(publicationId)/like")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body = try JSONSerialization.data(withJSONObject: ["userId": userId], options: [])
            request.httpBody = body

            let (data, response) = try await URLSession.shared.data(for: request)
            try validateResponse(response, data: data)

            let decoded = try JSONDecoder().decode(PublicationResponse.self, from: data)
            return .success(decoded)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Helpers réseau

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            let message = parseErrorMessage(from: data) ?? "Unknown error (\(http.statusCode))"
            throw NSError(
                domain: "PublicationService",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        }
    }

    private func parseErrorMessage(from data: Data) -> String? {
        do {
            let errorResponse = try JSONDecoder().decode(PublicationErrorResponse.self, from: data)
            if let any = errorResponse.message?.value {
                if let str = any as? String {
                    return str
                } else if let arr = any as? [String] {
                    return arr.joined(separator: ", ")
                }
            }
            return errorResponse.error
        } catch {
            return String(data: data, encoding: .utf8)
        }
    }

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

        // Obligatoires
        appendField(name: "author", value: author)
        appendField(name: "content", value: content)

        // tags & mentions -> "a,b,c" comme dans Android
        if let tags = tags, !tags.isEmpty {
            appendField(name: "tags", value: tags.joined(separator: ","))
        }
        if let mentions = mentions, !mentions.isEmpty {
            appendField(name: "mentions", value: mentions.joined(separator: ","))
        }
        if let location = location, !location.isEmpty {
            appendField(name: "location", value: location)
        }

        // Image
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"upload.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}
