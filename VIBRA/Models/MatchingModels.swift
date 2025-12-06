//
//  MatchingModels.swift
//  VIBRA
//
//  Modèles pour le système de matching
//

import Foundation

// MARK: - MatchingResponse
struct MatchingResponse: Codable {
    let userId: String
    let totalMatches: Int
    let matches: [UserMatch]
    let algorithm: String
    let parameters: MatchingParameters
}

// MARK: - UserMatch
struct UserMatch: Codable, Identifiable {
    let userId: String
    let similarity: Double
    let similarityPercent: String
    let distance: Double
    let user: MatchedUser
    let matchedPreferences: MatchedPreferences
    
    var id: String { userId }
}

// MARK: - MatchedUser
struct MatchedUser: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let avatar: String
    let gender: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName
        case lastName
        case email
        case avatar
        case gender = "Gender"
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var avatarURL: URL? {
        guard !avatar.isEmpty else { return nil }
        return URL(string: avatar)
    }
}

// MARK: - MatchedPreferences
struct MatchedPreferences: Codable {
    let level: PreferenceMatch?
    let cyclingType: PreferenceMatch?
    let cyclingFrequency: PreferenceMatchWithValues?
    let hikeType: PreferenceMatchWithValues?
    let hikeDuration: PreferenceMatchWithValues?
    let hikePreference: PreferenceMatch?
    let campingPractice: BooleanPreferenceMatch?
    let campingType: PreferenceMatchWithValues?
}

// MARK: - PreferenceMatch (avec champs optionnels pour gérer l'inconsistance API)
struct PreferenceMatch: Codable {
    let value: String?
    let match: Bool?
    
    // Valeurs par défaut sécurisées
    var safeValue: String { value ?? "N/A" }
    var safeMatch: Bool { match ?? false }
}

// MARK: - PreferenceMatchWithValues
struct PreferenceMatchWithValues: Codable {
    let userValue: String?
    let matchValue: String?
    let value: String?
    let match: Bool?
    
    var displayValue: String {
        // Priorité: value > userValue > matchValue
        if let value = value {
            return value
        } else if let userValue = userValue {
            return userValue
        } else if let matchValue = matchValue {
            return matchValue
        }
        return "N/A"
    }
    
    var comparisonText: String? {
        // Retourne un texte de comparaison seulement si userValue et matchValue existent et pas de match
        guard let match = match, !match else { return nil }
        
        if let userValue = userValue, let matchValue = matchValue {
            return "Vous: \(userValue) • Match: \(matchValue)"
        }
        return nil
    }
    
    var safeMatch: Bool { match ?? false }
}

// MARK: - BooleanPreferenceMatch
struct BooleanPreferenceMatch: Codable {
    let value: Bool?
    let match: Bool?
    
    var safeValue: Bool { value ?? false }
    var safeMatch: Bool { match ?? false }
}

// MARK: - MatchingParameters
struct MatchingParameters: Codable {
    let limit: Int
    let minSimilarity: Double
    let metric: String
    let candidatesAnalyzed: Int
}
