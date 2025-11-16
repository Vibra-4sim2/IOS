//
//  Camping.swift
//  VIBRA
//
//  Created by mac book pro on 11/16/25.
//

import Foundation

struct Camping: Codable {
    let id: String?
    let nom: String?
    let description: String?
    let lieu: String?
    let prix: Double?
    let dateDebut: String?
    let dateFin: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case nom
        case description
        case lieu
        case prix
        case dateDebut
        case dateFin
    }
    
    init(id: String?, nom: String?, description: String?, lieu: String?, prix: Double?, dateDebut: String?, dateFin: String?) {
        self.id = id
        self.nom = nom
        self.description = description
        self.lieu = lieu
        self.prix = prix
        self.dateDebut = dateDebut
        self.dateFin = dateFin
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id)
        nom = try c.decodeIfPresent(String.self, forKey: .nom)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        lieu = try c.decodeIfPresent(String.self, forKey: .lieu)
        // Flexible prix decoding: accepts Double/Int/String
        if let d = try? c.decodeIfPresent(Double.self, forKey: .prix) {
            prix = d
        } else if let i = try? c.decodeIfPresent(Int.self, forKey: .prix) {
            prix = Double(i)
        } else if let s = try? c.decodeIfPresent(String.self, forKey: .prix), let d = Double(s) {
            prix = d
        } else {
            prix = nil
        }
        dateDebut = try c.decodeIfPresent(String.self, forKey: .dateDebut)
        dateFin = try c.decodeIfPresent(String.self, forKey: .dateFin)
    }
}
