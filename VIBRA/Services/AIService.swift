//
//  AIService.swift
//  VIBRA
//
//  Service pour les fonctionnalités IA (Matching)
//

import Foundation

final class AIService {
    static let shared = AIService()
    private init() {}
    
    private var flaskURL: String { Constants.flaskURL }
    
    enum AIServiceError: Error, LocalizedError {
        case invalidURL
        case noToken
        case invalidResponse
        case decodingError
        case serverError(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "URL invalide"
            case .noToken:
                return "Token d'authentification manquant"
            case .invalidResponse:
                return "Réponse du serveur invalide"
            case .decodingError:
                return "Erreur de décodage des données"
            case .serverError(let message):
                return message
            }
        }
    }
    
    // MARK: - Get Matches
    func getMatches() async throws -> MatchingResponse {
        // Récupérer le token JWT
        guard let token = try? KeychainManager.shared.getJWT() else {
            print("❌ AIService: No JWT token found")
            throw AIServiceError.noToken
        }
        
        // Construire l'URL
        guard let url = URL(string: "\(flaskURL)/matching") else {
            print("❌ AIService: Invalid URL - \(flaskURL)/matching")
            throw AIServiceError.invalidURL
        }
        
        // Créer la requête
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        print("🔄 AIService: Fetching matches from \(url)")
        
        // Faire la requête
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("✅ AIService: Received response")
        
        // Vérifier la réponse HTTP
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ AIService: Invalid HTTP response")
            throw AIServiceError.invalidResponse
        }
        
        print("📊 AIService: HTTP Status Code: \(httpResponse.statusCode)")
        
        // Gérer les erreurs HTTP
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorMessage = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorMessage["error"] ?? errorMessage["message"] {
                print("❌ AIService: Server error - \(message)")
                throw AIServiceError.serverError(message)
            }
            print("❌ AIService: HTTP error - \(httpResponse.statusCode)")
            throw AIServiceError.serverError("Erreur serveur (\(httpResponse.statusCode))")
        }
        
        // Décoder la réponse
        do {
            let decoder = JSONDecoder()
            let matchingResponse = try decoder.decode(MatchingResponse.self, from: data)
            print("✅ AIService: Successfully decoded \(matchingResponse.totalMatches) matches")
            return matchingResponse
        } catch {
            print("❌ AIService: Decoding error - \(error)")
            
            // Debug détaillé
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("   🔑 Missing key: '\(key.stringValue)'")
                    print("   📍 Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                case .typeMismatch(let type, let context):
                    print("   ⚠️ Type mismatch: expected \(type)")
                    print("   📍 Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                    if let value = context.underlyingError {
                        print("   💡 Underlying: \(value)")
                    }
                case .valueNotFound(let type, let context):
                    print("   ⚠️ Value not found: \(type)")
                    print("   📍 Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                case .dataCorrupted(let context):
                    print("   💥 Data corrupted")
                    print("   📍 Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                @unknown default:
                    print("   ❓ Unknown decoding error")
                }
            }
            
            // Afficher un preview du JSON
            if let dataString = String(data: data, encoding: .utf8) {
                let preview = String(dataString.prefix(1000))
                print("📄 AIService: JSON preview (first 1000 chars):")
                print(preview)
                if dataString.count > 1000 {
                    print("   ... (\(dataString.count - 1000) more characters)")
                }
            }
            
            throw AIServiceError.decodingError
        }
    }
}
