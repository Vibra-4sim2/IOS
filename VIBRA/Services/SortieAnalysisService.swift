//
//  SortieAnalysisService.swift
//  VIBRA
//

import Foundation

final class SortieAnalysisService {
    static let shared = SortieAnalysisService()
    private init() {}
    
    private var flaskURL: String { Constants.flaskURL }
    
    enum AnalysisError: Error, LocalizedError {
        case invalidURL
        case noToken
        case invalidResponse
        case decodingError
        case serverError(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "URL invalide"
            case .noToken: return "Token d'authentification manquant"
            case .invalidResponse: return "Réponse du serveur invalide"
            case .decodingError: return "Erreur de décodage des données"
            case .serverError(let message): return message
            }
        }
    }
    
    func getPersonalizedAnalysis(sortieId: String) async throws -> SortieAnalysisResponse {
        guard let token = try? KeychainManager.shared.getJWT() else {
            throw AnalysisError.noToken
        }
        
        guard let url = URL(string: "\(flaskURL)/sortie/analyze/\(sortieId)/personalized") else {
            throw AnalysisError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AnalysisError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorMessage = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorMessage["error"] ?? errorMessage["message"] {
                throw AnalysisError.serverError(message)
            }
            throw AnalysisError.serverError("Erreur serveur (\(httpResponse.statusCode))")
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(SortieAnalysisResponse.self, from: data)
        } catch {
            throw AnalysisError.decodingError
        }
    }
}
