//
//  RatingService.swift
//  VIBRA
//

import Foundation

enum RatingServiceError: Error {
    case invalidURL
    case invalidResponse
    case serverError(String)
    case decodingError
}

final class RatingService {
    static let shared = RatingService()
    
    private let baseURL: String
    
    private init() {
        self.baseURL = Constants.baseURL
    }
    
    private func authorizedRequest(url: URL, method: String) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let token = try KeychainManager.shared.getJWT()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    /// Get creator rating summary
    func getCreatorRating(userId: String) async throws -> UserRating {
        let urlString = "\(baseURL)/ratings/creator/\(userId)"
        guard let url = URL(string: urlString) else {
            throw RatingServiceError.invalidURL
        }
        
        let request = try authorizedRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw RatingServiceError.invalidResponse
        }
        
        let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
        print("🛰 getCreatorRating HTTP \(http.statusCode)")
        print("🧾 RAW JSON:", bodyString.prefix(400), "…")
        
        guard (200...299).contains(http.statusCode) else {
            throw RatingServiceError.serverError(bodyString)
        }
        
        do {
            let rating = try JSONDecoder().decode(UserRating.self, from: data)
            return rating
        } catch {
            print("❌ getCreatorRating decoding error:", error)
            throw RatingServiceError.decodingError
        }
    }

    // MARK: - Sortie rating eligibility
    func getEligibleSortieRatings() async throws -> [RatingEligibleSortie] {
        let urlString = "\(baseURL)/ratings/eligible"
        guard let url = URL(string: urlString) else {
            throw RatingServiceError.invalidURL
        }
        let request = try authorizedRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RatingServiceError.invalidResponse
        }
        let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
        print("🌐 getEligibleSortieRatings HTTP \(http.statusCode)")
        print("RAW JSON eligible:", bodyString.prefix(400), "…")
        guard (200...299).contains(http.statusCode) else {
            throw RatingServiceError.serverError(bodyString)
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([RatingEligibleSortie].self, from: data)
        } catch {
            print("❌ getEligibleSortieRatings decoding error:", error)
            throw RatingServiceError.decodingError
        }
    }

    // MARK: - Submit sortie rating
    func submitSortieRating(sortieId: String, requestBody: SubmitSortieRatingRequest) async throws {
        let urlString = "\(baseURL)/ratings/sortie/\(sortieId)"
        guard let url = URL(string: urlString) else {
            throw RatingServiceError.invalidURL
        }
        var request = try authorizedRequest(url: url, method: "POST")
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw RatingServiceError.serverError("Encoding error: \(error.localizedDescription)")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RatingServiceError.invalidResponse
        }
        let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
        print("submitSortieRating HTTP \(http.statusCode)")
        print("RAW JSON submit:", bodyString.prefix(400), "…")
        guard (200...299).contains(http.statusCode) else {
            throw RatingServiceError.serverError(bodyString)
        }
    }
    
    // MARK: - New: recompute creator rating then fetch
    /// Force recomputation of a creator's rating summary on the backend.
    ///
    /// Corresponds to POST /ratings/recompute/creator/{userId}
    func recomputeCreatorRating(userId: String) async throws {
        let urlString = "\(baseURL)/ratings/recompute/creator/\(userId)"
        guard let url = URL(string: urlString) else {
            throw RatingServiceError.invalidURL
        }
        let request = try authorizedRequest(url: url, method: "POST")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RatingServiceError.invalidResponse
        }
        let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
        print("🛰 recomputeCreatorRating HTTP \(http.statusCode)")
        print("🧾 recompute RAW JSON:", bodyString.prefix(400), "…")
        guard (200...299).contains(http.statusCode) else {
            throw RatingServiceError.serverError(bodyString)
        }
        // We don't need to decode the body; success status is enough.
    }
    /// Convenience: ensure recompute is triggered before fetching the latest rating.
    func refreshAndGetCreatorRating(userId: String) async throws -> UserRating {
        // First, force backend recomputation
        try await recomputeCreatorRating(userId: userId)
        // Then fetch the freshly computed rating
        return try await getCreatorRating(userId: userId)
    }
}
