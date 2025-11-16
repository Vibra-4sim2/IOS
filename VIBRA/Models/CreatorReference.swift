//
//  CreatorReference.swift
//  VIBRA
//
//  Created by mac book pro on 11/16/25.
//

import Foundation

// Modèle simplifié pour le createurId dans la réponse API
struct CreatorReference: Codable {
    let id: String
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email
    }
}
