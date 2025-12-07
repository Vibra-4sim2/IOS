//
//  RecommendationsResponse.swift
//  VIBRA
//
//  DTO pour la réponse de l'API recommendations
//

import Foundation

struct RecommendationsResponse: Codable {
    let userId: String
    let userCluster: Int?
    let recommendations: [Ride]
    
    enum CodingKeys: String, CodingKey {
        case userId
        case userCluster
        case recommendations
    }
}
