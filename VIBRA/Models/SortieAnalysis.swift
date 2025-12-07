//
//  SortieAnalysis.swift
//  VIBRA
//

import Foundation

// MARK: - Analysis Response
struct SortieAnalysisResponse: Codable {
    let success: Bool
    let sortie: AnalyzedSortie?
    let analysis: DifficultyAnalysis?
    let personalizedTips: [String]?
    let safetyWarnings: [String]?
    let preparationChecklist: [String]?
    let nutritionTips: [String]?
    let equipment: [Equipment]?
    let equipmentSummary: EquipmentSummary?
    let metadata: AnalysisMetadata?
    
    enum CodingKeys: String, CodingKey {
        case success, sortie, analysis
        case personalizedTips = "personalized_tips"
        case safetyWarnings = "safety_warnings"
        case preparationChecklist = "preparation_checklist"
        case nutritionTips = "nutrition_tips"
        case equipment
        case equipmentSummary = "equipment_summary"
        case metadata
    }
}

struct AnalyzedSortie: Codable {
    let id: String?
    let titre: String?
    let type: String?
    let difficulte: String?
    let date: String?
    let optionCamping: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case titre, type, difficulte, date
        case optionCamping = "option_camping"
    }
}

struct DifficultyAnalysis: Codable {
    let difficultyScore: Int?
    let difficultyLabel: String?
    let estimatedDuration: String?
    let physicalDemand: String?
    let technicalDemand: String?
    let weatherSensitivity: String?
    let bestSeason: String?
    
    enum CodingKeys: String, CodingKey {
        case difficultyScore = "difficulty_score"
        case difficultyLabel = "difficulty_label"
        case estimatedDuration = "estimated_duration"
        case physicalDemand = "physical_demand"
        case technicalDemand = "technical_demand"
        case weatherSensitivity = "weather_sensitivity"
        case bestSeason = "best_season"
    }
}

struct Equipment: Codable, Identifiable {
    let key: String
    let name: String
    let category: String
    let image: String?
    let description: String
    let buyLink: String?
    let priceRange: String?
    let necessity: String
    let necessityReason: String?
    
    var id: String { key }
    
    enum CodingKeys: String, CodingKey {
        case key, name, category, image, description
        case buyLink = "buy_link"
        case priceRange = "price_range"
        case necessity
        case necessityReason = "necessity_reason"
    }
    
    var necessityLevel: NecessityLevel {
        NecessityLevel(rawValue: necessity) ?? .optional
    }
}

enum NecessityLevel: String, CaseIterable {
    case essential = "essential"
    case recommended = "recommended"
    case optional = "optional"
    
    var displayName: String {
        switch self {
        case .essential: return "Essentiel"
        case .recommended: return "Recommandé"
        case .optional: return "Optionnel"
        }
    }
}

struct EquipmentSummary: Codable {
    let essentialCount: Int?
    let recommendedCount: Int?
    let optionalCount: Int?
    let totalEstimatedCost: String?
    
    enum CodingKeys: String, CodingKey {
        case essentialCount = "essential_count"
        case recommendedCount = "recommended_count"
        case optionalCount = "optional_count"
        case totalEstimatedCost = "total_estimated_cost"
    }
}

struct AnalysisMetadata: Codable {
    let analyzedAt: String?
    let personalized: Bool?
    let userLevel: String?
    let geminiSuccess: Bool?
    
    enum CodingKeys: String, CodingKey {
        case analyzedAt = "analyzed_at"
        case personalized
        case userLevel = "user_level"
        case geminiSuccess = "gemini_success"
    }
}
