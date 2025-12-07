import Foundation

final class PollService {
    static let shared = PollService()
    private init() {}

    private var baseURL: String { Constants.baseURL }

    enum PollServiceError: Error, LocalizedError {
        case invalidURL
        case invalidResponse
        case decodingError
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "URL invalide"
            case .invalidResponse: return "Réponse du serveur invalide"
            case .decodingError: return "Erreur de décodage"
            case .serverError(let message): return message
            }
        }
    }

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

    // MARK: - REST endpoints

    func createPoll(chatId: String, question: String, options: [String], allowMultiple: Bool, closesAt: Date?) async throws -> Poll {
        let urlString = "\(baseURL)/polls/\(chatId)"
        guard let url = URL(string: urlString) else { throw PollServiceError.invalidURL }

        var body: [String: Any] = [
            "question": question,
            "options": options,
            "allowMultiple": allowMultiple
        ]
        if let closesAt = closesAt {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            body["closesAt"] = iso.string(from: closesAt)
        }

        let request = try authorizedRequest(url: url, method: "POST", jsonBody: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PollServiceError.invalidResponse
        }

        let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
        print("🛰 createPoll HTTP \(http.statusCode)")
        print("🧾 RAW JSON:", bodyString.prefix(400), "…")

        guard (200...299).contains(http.statusCode) else {
            throw PollServiceError.serverError(bodyString)
        }

        do {
            return try JSONDecoder().decode(Poll.self, from: data)
        } catch {
            print("❌ createPoll decoding error:", error)
            throw PollServiceError.decodingError
        }
    }

    func vote(pollId: String, optionIds: [String]) async throws -> Poll {
        let urlString = "\(baseURL)/polls/\(pollId)/vote"
        guard let url = URL(string: urlString) else { throw PollServiceError.invalidURL }

        let body: [String: Any] = [
            "optionIds": optionIds
        ]

        let request = try authorizedRequest(url: url, method: "POST", jsonBody: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PollServiceError.invalidResponse
        }

        let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
        print("🛰 votePoll HTTP \(http.statusCode)")
        print("🧾 RAW JSON:", bodyString.prefix(400), "…")

        guard (200...299).contains(http.statusCode) else {
            throw PollServiceError.serverError(bodyString)
        }

        do {
            return try JSONDecoder().decode(Poll.self, from: data)
        } catch {
            print("❌ votePoll decoding error:", error)
            throw PollServiceError.decodingError
        }
    }

    func closePoll(pollId: String) async throws -> Poll {
        let urlString = "\(baseURL)/polls/\(pollId)/close"
        guard let url = URL(string: urlString) else { throw PollServiceError.invalidURL }

        let request = try authorizedRequest(url: url, method: "PATCH")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PollServiceError.invalidResponse
        }

        let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
        print("🛰 closePoll HTTP \(http.statusCode)")
        print("🧾 RAW JSON:", bodyString.prefix(400), "…")

        guard (200...299).contains(http.statusCode) else {
            throw PollServiceError.serverError(bodyString)
        }

        do {
            return try JSONDecoder().decode(Poll.self, from: data)
        } catch {
            print("❌ closePoll decoding error:", error)
            throw PollServiceError.decodingError
        }
    }

    func getChatPolls(chatId: String, page: Int = 1, limit: Int = 10) async throws -> PaginatedPollsResponse {
        let urlString = "\(baseURL)/polls/chat/\(chatId)?page=\(page)&limit=\(limit)"
        guard let url = URL(string: urlString) else { throw PollServiceError.invalidURL }

        let request = try authorizedRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PollServiceError.invalidResponse
        }

        let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
        print("🛰 getChatPolls HTTP \(http.statusCode)")
        print("🧾 RAW JSON:", bodyString.prefix(400), "…")

        guard (200...299).contains(http.statusCode) else {
            throw PollServiceError.serverError(bodyString)
        }

        do {
            return try JSONDecoder().decode(PaginatedPollsResponse.self, from: data)
        } catch {
            print("❌ getChatPolls decoding error:", error)
            throw PollServiceError.decodingError
        }
    }

    func getPoll(pollId: String) async throws -> Poll {
        let urlString = "\(baseURL)/polls/\(pollId)"
        guard let url = URL(string: urlString) else { throw PollServiceError.invalidURL }

        let request = try authorizedRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PollServiceError.invalidResponse
        }

        let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
        print("🛰 getPoll HTTP \(http.statusCode)")
        print("🧾 RAW JSON:", bodyString.prefix(400), "…")

        guard (200...299).contains(http.statusCode) else {
            throw PollServiceError.serverError(bodyString)
        }

        do {
            return try JSONDecoder().decode(Poll.self, from: data)
        } catch {
            print("❌ getPoll decoding error:", error)
            throw PollServiceError.decodingError
        }
    }
}
