//
//  AIService+Itinerary.swift
//  VIBRA
//
//  Extension pour la génération d'itinéraire IA
//

import Foundation
import CoreLocation

extension AIService {

    /// Génère un itinéraire personnalisé avec l'IA
    func generateAIItinerary(
        start: CLLocationCoordinate2D,
        end: CLLocationCoordinate2D,
        startName: String? = nil,
        endName: String? = nil,
        context: String? = nil,
        activityType: String
    ) async throws -> AIItineraryResponse {

        guard let token = try? KeychainManager.shared.getJWT() else {
            throw AIServiceError.noToken
        }

        guard let url = URL(string: "\(Constants.flaskURL)/itinerary/generate") else {
            throw AIServiceError.invalidURL
        }

        let mappedActivityType = mapActivityTypeForAI(activityType)

        let requestBody = AIItineraryRequest(
            start: AILocationPoint(lat: start.latitude, lon: start.longitude, displayName: startName),
            end: AILocationPoint(lat: end.latitude, lon: end.longitude, displayName: endName),
            context: context,
            activityType: mappedActivityType
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            if let msg = try? JSONDecoder().decode([String: String].self, from: data),
               let message = msg["error"] ?? msg["message"] {
                throw AIServiceError.serverError(message)
            }
            throw AIServiceError.serverError("Erreur serveur (\(http.statusCode))")
        }

        do {
            return try JSONDecoder().decode(AIItineraryResponse.self, from: data)
        } catch {
            throw AIServiceError.decodingError
        }
    }

    /// Mappe le type d'activité UI vers le format attendu par l'API IA
    private func mapActivityTypeForAI(_ typeUI: String) -> String {
        switch typeUI {
        case "RANDO": return "RANDONNEE"
        case "VELO_ELECTRIQUE": return "VELO"
        case "CAMPING": return "RANDONNEE" // camping -> profil rando
        default: return typeUI
        }
    }
}
