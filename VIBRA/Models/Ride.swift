//
//  Ride.swift
//  VIBRA
//
//  Created by mac book pro on 11/16/25.
//

import Foundation

struct Ride: Codable, Identifiable {
    let id: String?
    let titre: String
    let description: String?
    let date: String?
    let type: String?
    let optionCamping: Bool?
    let createurId: String?
    var creator: User?
    let photo: String?
    let campingId: String?
    let camping: Camping?
    let capacite: Int?
    let distance: Int?
    let dureeEstimee: Int?
    // New: start/end points for itinerary
    let pointDepart: GeoPoint?
    let pointArrivee: GeoPoint?
    // New: difficulty if provided by backend
    let difficulte: String?
    // Participants from backend: could be [User] or [String] (ids)
    let participants: [User]?
    let participantIds: [String]?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case titre
        case description
        case date
        case type
        case optionCamping = "option_camping"
        case createurId
        case creator
        case photo
        case camping
        case capacite
        case distance
        case dureeEstimee = "duree_estimee"
        case pointDepart
        case pointArrivee
        case difficulte
        case itineraire // NEW
        case participants
    }

    // NEW: nested itinerary object support
    private struct Itineraire: Codable {
        let pointDepart: GeoPoint?
        let pointArrivee: GeoPoint?
        let distance: Double?
        let dureeEstimee: Double?
        enum CodingKeys: String, CodingKey {
            case pointDepart
            case pointArrivee
            case distance
            case dureeEstimee = "duree_estimee"
        }
        init(pointDepart: GeoPoint?, pointArrivee: GeoPoint?, distance: Double?, dureeEstimee: Double?) {
            self.pointDepart = pointDepart
            self.pointArrivee = pointArrivee
            self.distance = distance
            self.dureeEstimee = dureeEstimee
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            pointDepart = try c.decodeIfPresent(GeoPoint.self, forKey: .pointDepart)
            pointArrivee = try c.decodeIfPresent(GeoPoint.self, forKey: .pointArrivee)
            distance = c.decodeFlexibleDouble(forKey: .distance)
            dureeEstimee = c.decodeFlexibleDouble(forKey: .dureeEstimee)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        titre = try container.decodeIfPresent(String.self, forKey: .titre) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)
        date = try container.decodeIfPresent(String.self, forKey: .date)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        optionCamping = try container.decodeIfPresent(Bool.self, forKey: .optionCamping)
        photo = try container.decodeIfPresent(String.self, forKey: .photo)
        capacite = try container.decodeIfPresent(Int.self, forKey: .capacite)
        difficulte = try container.decodeIfPresent(String.self, forKey: .difficulte)

        // creator field (string/object) resolution
        if let idString = try? container.decodeIfPresent(String.self, forKey: .createurId) {
            createurId = idString
            creator = nil
        } else if let creatorRef = try? container.decodeIfPresent(CreatorReference.self, forKey: .createurId) {
            createurId = creatorRef.id
            creator = nil
        } else if let creatorObj = try? container.decodeIfPresent(User.self, forKey: .createurId) {
            creator = creatorObj
            createurId = creatorObj.id
        } else {
            createurId = nil
            creator = nil
        }

        // camping resolution
        if let campingString = try? container.decodeIfPresent(String.self, forKey: .camping) {
            campingId = campingString
            camping = nil
        } else if let campingObj = try? container.decodeIfPresent(Camping.self, forKey: .camping) {
            camping = campingObj
            campingId = campingObj.id
        } else {
            campingId = nil
            camping = nil
        }

        // Top-level values (may be nil)
        let topPointDepart = try container.decodeIfPresent(GeoPoint.self, forKey: .pointDepart)
        let topPointArrivee = try container.decodeIfPresent(GeoPoint.self, forKey: .pointArrivee)
        let topDistanceDouble = container.decodeFlexibleDouble(forKey: .distance)
        let topDureeDouble = container.decodeFlexibleDouble(forKey: .dureeEstimee)

        // Nested itineraire fallback
        let itin = try container.decodeIfPresent(Itineraire.self, forKey: .itineraire)

        pointDepart = topPointDepart ?? itin?.pointDepart
        pointArrivee = topPointArrivee ?? itin?.pointArrivee
        // Prefer top-level numeric if available; else fallback to itineraire
        let resolvedDistance = topDistanceDouble ?? itin?.distance
        let resolvedDuree = topDureeDouble ?? itin?.dureeEstimee
        distance = resolvedDistance.map { Int($0.rounded()) }
        dureeEstimee = resolvedDuree.map { Int($0.rounded()) }

        // Participants flexible decode
        if let users = try? container.decodeIfPresent([User].self, forKey: .participants) {
            participants = users
            participantIds = users.compactMap { $0.id }
        } else if let ids = try? container.decodeIfPresent([String].self, forKey: .participants) {
            participants = nil
            participantIds = ids
        } else {
            participants = nil
            participantIds = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(titre, forKey: .titre)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(optionCamping, forKey: .optionCamping)
        if let cid = createurId { try container.encode(cid, forKey: .createurId) }
        try container.encodeIfPresent(photo, forKey: .photo)
        if let campId = campingId { try container.encode(campId, forKey: .camping) }
        try container.encodeIfPresent(capacite, forKey: .capacite)
        try container.encodeIfPresent(distance, forKey: .distance)
        try container.encodeIfPresent(dureeEstimee, forKey: .dureeEstimee)
        try container.encodeIfPresent(pointDepart, forKey: .pointDepart)
        try container.encodeIfPresent(pointArrivee, forKey: .pointArrivee)
        try container.encodeIfPresent(difficulte, forKey: .difficulte)
        // mirror nested object for compatibility
        if pointDepart != nil || pointArrivee != nil || distance != nil || dureeEstimee != nil {
            let itin = Itineraire(
                pointDepart: pointDepart,
                pointArrivee: pointArrivee,
                distance: distance.map(Double.init),
                dureeEstimee: dureeEstimee.map(Double.init)
            )
            try container.encode(itin, forKey: .itineraire)
        }
        // Participants encoding (prefer full users if available)
        if let users = participants {
            try container.encode(users, forKey: .participants)
        } else if let ids = participantIds {
            try container.encode(ids, forKey: .participants)
        }
    }
}

// New: simple latitude/longitude object from backend
struct GeoPoint: Codable {
    let latitude: Double
    let longitude: Double
}

// MARK: - Decoding helpers
private extension KeyedDecodingContainer {
    func decodeFlexibleDouble(forKey key: Key) -> Double? {
        // Try Double directly
        if let val = try? decodeIfPresent(Double.self, forKey: key) {
            return val
        }
        // Try Int and cast
        if let intVal = try? decodeIfPresent(Int.self, forKey: key) {
            return Double(intVal)
        }
        // Try String -> Double
        if let str = try? decodeIfPresent(String.self, forKey: key) {
            return Double(str)
        }
        return nil
    }
}
// MARK: - Creator Reference (for populated createurId)
struct CreatorReference: Codable {
    let id: String
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email
    }
}
