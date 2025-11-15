//
//  SortieService.swift
//  VIBRA
//
//  Created by mac book pro on 11/15/25.
//  Version corrigée — endpoint /geojson + fallback decoders
//
import Foundation
import CoreLocation

// MARK: - DTOs pour le backend

struct PointDTO: Codable {
    let latitude: Double
    let longitude: Double
    let display_name: String?
    let address: String?
}

struct ItineraireDTO: Codable {
    let pointDepart: PointDTO
    let pointArrivee: PointDTO
    let description: String?
    let distance: Double?          // en mètres
    let duree_estimee: Double?     // en secondes
    let geometry: [[Double]]?      // [ [lon, lat], ... ]
    let instructions: [String]?    // texte des étapes
}

// Camping DTOs (aligné sur CreateCampingDto NestJS)
struct CreateCampingRequest: Codable {
    let nom: String
    let description: String?
    let lieu: String
    let prix: Double?
    let participants: Int?
    let dateDebut: String // ISO8601
    let dateFin: String   // ISO8601
}

struct CampingResponse: Codable {
    let _id: String
    let nom: String
    let description: String?
    let lieu: String
    let prix: Double?
    let participants: Int?
    let dateDebut: String
    let dateFin: String
}

// Sortie DTO (aligné sur ton schema Sortie)
struct CreateSortieRequest: Codable {
    let titre: String
    let description: String?
    let date: String              // ISO8601
    let type: String              // SortieType raw: "RANDO", "VELO_ELECTRIQUE", etc.
    let option_camping: Bool
    let photo: String?
    let camping: String?          // ObjectId camping
    let capacite: Int?
    let itineraire: ItineraireDTO?
}

struct SortieResponse: Codable {
    let _id: String
    let titre: String
}

// MARK: - OpenRouteService DTOs (GeoJSON / directions)

/*
 GeoJSON response structure (directions/{profile}/geojson) typical:
 {
   "type":"FeatureCollection",
   "features":[
      {
        "type":"Feature",
        "properties":{
           "segments":[ { "distance":..., "duration":..., "steps":[{ "instruction":... }, ...] } ],
           "summary": { "distance":..., "duration":... }
         },
        "geometry": { "coordinates": [ [lon,lat], ... ] }
      }
   ]
 }
*/

struct ORSFeatureCollection: Codable {
    let features: [ORSFeature]
}

struct ORSFeature: Codable {
    let properties: ORSProperties
    let geometry: ORSGeometry
}

struct ORSProperties: Codable {
    let segments: [ORSSegment]
    let summary: ORSSummary
}

struct ORSSegment: Codable {
    let distance: Double
    let duration: Double
    let steps: [ORSStep]
}

struct ORSStep: Codable {
    let instruction: String
}

struct ORSSummary: Codable {
    let distance: Double
    let duration: Double
}

struct ORSGeometry: Codable {
    let coordinates: [[Double]]   // [ [lon, lat], ... ]
}

// Fallback shape (JSON variant) : {"routes":[{ "segments":[...], "summary": {...}, "geometry": { "coordinates": [...] } }]}
struct ORSRoutesWrapper: Codable {
    let routes: [ORSRoutesItem]
}

struct ORSRoutesItem: Codable {
    let segments: [ORSSegment]?
    let summary: ORSSummary?
    let geometry: ORSGeometry?
}

// MARK: - Erreurs

enum SortieServiceError: Error {
    case invalidBaseURL
    case invalidResponse
    case decodingError
    case openRouteError
    case missingItineraire
}

// MARK: - Service

final class SortieService {
    static let shared = SortieService()
    
    private let baseURL: URL
    private let openRouteApiKey: String
    
    private init() {
        guard let url = URL(string: Constants.baseURL) else {
            fatalError("Constants.baseURL invalide")
        }
        self.baseURL = url
        self.openRouteApiKey = Constants.openRouteApiKey
    }
    
    // MARK: - Camping
    
    func createCamping(_ camping: CreateCampingRequest) async throws -> CampingResponse {
        let url = baseURL.appendingPathComponent("campings")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(camping)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            #if DEBUG
            print("createCamping status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            print(String(data: data, encoding: .utf8) ?? "no body")
            #endif
            throw SortieServiceError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode(CampingResponse.self, from: data)
        } catch {
            throw SortieServiceError.decodingError
        }
    }
    
    // MARK: - Sortie
    
    func createSortie(_ sortie: CreateSortieRequest) async throws -> SortieResponse {
        let url = baseURL.appendingPathComponent("sorties")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(sortie)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            #if DEBUG
            print("createSortie status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            print(String(data: data, encoding: .utf8) ?? "no body")
            #endif
            throw SortieServiceError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode(SortieResponse.self, from: data)
        } catch {
            throw SortieServiceError.decodingError
        }
    }
    
    // MARK: - OpenRouteService
    
    /// Retourne l’URL ORS en fonction du type de sortie (on force /geojson)
    private func openRouteURL(for type: String) -> URL {
        let base = "https://api.openrouteservice.org/v2/directions/"
        let profile: String
        switch type {
        case "VELO_ELECTRIQUE":
            profile = "cycling-regular"
        case "RANDO":
            profile = "foot-walking"
        default:
            profile = "foot-walking"
        }
        // On ajoute explicitement /geojson pour forcer le format attendu
        let full = base + profile + "/geojson"
        return URL(string: full)!
    }
    
    /// Appel OpenRouteService pour obtenir l’itinéraire entre start et end.
    /// `typeSortie` permet de choisir dynamiquement le bon profil (rando / vélo).
    func fetchItineraire(
        start: CLLocationCoordinate2D,
        end: CLLocationCoordinate2D,
        typeSortie: String,
        departName: String? = nil,
        arriveeName: String? = nil
    ) async throws -> ItineraireDTO {
        
        let url = openRouteURL(for: typeSortie)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(openRouteApiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        // On précise qu'on accepte du GeoJSON/JSON
        request.setValue("application/json, application/geo+json, application/geojson", forHTTPHeaderField: "Accept")
        
        // Body conforme à la doc ORS
        let body: [String: Any] = [
            "coordinates": [
                [start.longitude, start.latitude],
                [end.longitude, end.latitude]
            ],
            "instructions": true,
            "geometry": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        #if DEBUG
        if let http = response as? HTTPURLResponse {
            print("ORS status: \(http.statusCode)")
        }
        if let json = String(data: data, encoding: .utf8) {
            print("ORS raw response: \(json)")
        }
        #endif
        
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw SortieServiceError.openRouteError
        }
        
        let decoder = JSONDecoder()
        
        // 1) Essayer GeoJSON (FeatureCollection) — le plus courant avec /geojson
        if let orsFeatureCollection = try? decoder.decode(ORSFeatureCollection.self, from: data),
           let feature = orsFeatureCollection.features.first {
            
            let summary = feature.properties.summary
            let segment = feature.properties.segments.first
            let distance = summary.distance
            let duree = summary.duration
            let instructions = segment?.steps.map { $0.instruction } ?? []
            let coords = feature.geometry.coordinates
            
            let pointDepart = PointDTO(
                latitude: start.latitude,
                longitude: start.longitude,
                display_name: departName,
                address: departName
            )
            let pointArrivee = PointDTO(
                latitude: end.latitude,
                longitude: end.longitude,
                display_name: arriveeName,
                address: arriveeName
            )
            
            return ItineraireDTO(
                pointDepart: pointDepart,
                pointArrivee: pointArrivee,
                description: nil,
                distance: distance,
                duree_estimee: duree,
                geometry: coords,
                instructions: instructions
            )
        }
        
        // 2) Fallback: essayer le format `routes` (parfois renvoyé si Accept diffère)
        if let orsRoutes = try? decoder.decode(ORSRoutesWrapper.self, from: data),
           let route = orsRoutes.routes.first {
            
            let summary = route.summary
            let segment = route.segments?.first
            let distance = summary?.distance
            let duree = summary?.duration
            let instructions = segment?.steps.map { $0.instruction } ?? []
            let coords = route.geometry?.coordinates
            
            let pointDepart = PointDTO(
                latitude: start.latitude,
                longitude: start.longitude,
                display_name: departName,
                address: departName
            )
            let pointArrivee = PointDTO(
                latitude: end.latitude,
                longitude: end.longitude,
                display_name: arriveeName,
                address: arriveeName
            )
            
            return ItineraireDTO(
                pointDepart: pointDepart,
                pointArrivee: pointArrivee,
                description: nil,
                distance: distance,
                duree_estimee: duree,
                geometry: coords,
                instructions: instructions
            )
        }
        
        // Si on arrive ici -> échec décodage
        throw SortieServiceError.decodingError
    }
}
