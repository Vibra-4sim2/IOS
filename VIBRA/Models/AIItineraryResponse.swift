//
//  AIItineraryResponse.swift
//  VIBRA
//
//  Modèles pour la réponse de l'API d'itinéraire IA
//

import Foundation

// MARK: - Réponse principale de l'API IA

struct AIItineraryResponse: Codable {
    let success: Bool
    let itinerary: AIItinerary
    let personalization: AIPersonalization
    let aiRecommendations: AIRecommendations
    let metadata: AIMetadata

    enum CodingKeys: String, CodingKey {
        case success
        case itinerary
        case personalization
        case aiRecommendations = "ai_recommendations"
        case metadata
    }
}

// MARK: - Itinéraire

struct AIItinerary: Codable {
    let summary: AIItinerarySummary
    let geometry: AIGeometry
    let instructions: [AIInstruction]
}

struct AIGeometry: Codable {
    let coordinates: [[Double]] // Array of [lon, lat, elevation]
}

struct AIItinerarySummary: Codable {
    let distance: Double // km
    let duration: Double // minutes
    let ascent: Double
    let descent: Double
}

struct AIInstruction: Codable {
    let instruction: String
    let distance: Double
    let duration: Double
    let type: Int
    let name: String
    let wayPoints: [Int]

    enum CodingKeys: String, CodingKey {
        case instruction, distance, duration, type, name
        case wayPoints = "way_points"
    }
}

// MARK: - Personnalisation

struct AIPersonalization: Codable {
    let profileUsed: String
    let difficultyAssessment: String
    let difficultyScore: Int
    let elevationPreference: String
    let scenicRoute: Bool
    let routePreference: String

    enum CodingKeys: String, CodingKey {
        case profileUsed = "profile_used"
        case difficultyAssessment = "difficulty_assessment"
        case difficultyScore = "difficulty_score"
        case elevationPreference = "elevation_preference"
        case scenicRoute = "scenic_route"
        case routePreference = "route_preference"
    }
}

// MARK: - Recommandations IA

struct AIRecommendations: Codable {
    let suggestedStops: [String]
    let safetyTips: [String]
    let equipmentSuggestions: [String]
    let bestTimeOfDay: String
    let weatherConsiderations: String
    let personalizedTips: [String]
    let alternativeSuggestion: String

    enum CodingKeys: String, CodingKey {
        case suggestedStops = "suggested_stops"
        case safetyTips = "safety_tips"
        case equipmentSuggestions = "equipment_suggestions"
        case bestTimeOfDay = "best_time_of_day"
        case weatherConsiderations = "weather_considerations"
        case personalizedTips = "personalized_tips"
        case alternativeSuggestion = "alternative_suggestion"
    }
}

// MARK: - Metadata

struct AIMetadata: Codable {
    let generatedBy: String
    let geminiAnalysisSuccess: Bool
    let userLevel: String
    let activityType: String

    enum CodingKeys: String, CodingKey {
        case generatedBy = "generated_by"
        case geminiAnalysisSuccess = "gemini_analysis_success"
        case userLevel = "user_level"
        case activityType = "activity_type"
    }
}

// MARK: - Request Body

struct AIItineraryRequest: Codable {
    let start: AILocationPoint
    let end: AILocationPoint
    let context: String?
    let activityType: String

    enum CodingKeys: String, CodingKey {
        case start, end, context
        case activityType = "activity_type"
    }
}

struct AILocationPoint: Codable {
    let lat: Double
    let lon: Double
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case lat, lon
        case displayName = "display_name"
    }
}
