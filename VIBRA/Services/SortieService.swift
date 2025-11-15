//
//  SortieService.swift
//  VIBRA
//
//  Service Sortie/Camping + ORS avec auth JWT + multipart /sorties
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

// Sortie DTO retourné par le backend
struct SortieResponse: Codable {
    let _id: String
    let titre: String?
}

// MARK: - OpenRouteService DTOs (GeoJSON / directions)

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

// Fallback shape : {"routes":[{ "segments":[...], "summary": {...}, "geometry": { "coordinates": [...] } }]}
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
    case unauthorized       // 401
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
    
    // MARK: - Helpers Auth
    
    private func applyAuthHeader(to request: inout URLRequest) {
        if let token = try? KeychainManager.shared.getJWT(), !token.isEmpty {
            let headerValue = "Bearer \(token)"
            request.setValue(headerValue, forHTTPHeaderField: "Authorization")
            #if DEBUG
            print("[AUTH] Authorization header set: Bearer \(token.prefix(16))...")
            #endif
        } else {
            #if DEBUG
            print("[AUTH] No JWT found in Keychain – Authorization header NOT set")
            #endif
        }
    }
    
    // MARK: - Camping
    
    func createCamping(_ camping: CreateCampingRequest) async throws -> CampingResponse {
        let url = baseURL.appendingPathComponent("campings")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyAuthHeader(to: &request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(camping)
        
        #if DEBUG
        print("[HTTP] POST \(url.absoluteString) (createCamping)")
        if let bodyString = String(data: request.httpBody ?? Data(), encoding: .utf8) {
            print("[HTTP] Request body (camping): \(bodyString)")
        }
        print("[HTTP] Headers (camping): \(request.allHTTPHeaderFields ?? [:])")
        #endif
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SortieServiceError.invalidResponse
        }
        
        #if DEBUG
        print("[HTTP] createCamping status: \(http.statusCode)")
        print("[HTTP] createCamping raw response: \(String(data: data, encoding: .utf8) ?? "no body")")
        #endif
        
        if http.statusCode == 401 {
            throw SortieServiceError.unauthorized
        }
        
        guard (200..<300).contains(http.statusCode) else {
            throw SortieServiceError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode(CampingResponse.self, from: data)
        } catch {
            throw SortieServiceError.decodingError
        }
    }
    
    // MARK: - Sortie (multipart/form-data)
    
    struct CreateSortieMultipartPayload {
        let titre: String
        let description: String?
        let dateISO: String
        let type: String
        let optionCamping: Bool
        let photoURL: String?          // URL de la photo saisie par l’utilisateur
        let lieu: String?
        let difficulte: String?
        let niveau: String?
        let capacite: Int?
        let prix: Double?
        let campingId: String?
        let itineraireJSON: String     // JSON.stringify(Itineraire)
        let campingJSON: String?       // JSON.stringify(camping) si cohérent
    }
    
    func createSortieMultipart(_ payload: CreateSortieMultipartPayload) async throws -> SortieResponse {
        let url = baseURL.appendingPathComponent("sorties")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyAuthHeader(to: &request)
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        func appendFormField(name: String, value: String) {
            let field = """
            --\(boundary)\r
            Content-Disposition: form-data; name=\"\(name)\"\r
            \r
            \(value)\r

            """
            if let data = field.data(using: .utf8) {
                body.append(data)
            }
        }
        
        // Champs texte principaux
        appendFormField(name: "titre", value: payload.titre)
        if let desc = payload.description {
            appendFormField(name: "description", value: desc)
        }
        appendFormField(name: "date", value: payload.dateISO)
        appendFormField(name: "type", value: payload.type)
        appendFormField(name: "option_camping", value: payload.optionCamping ? "true" : "false")
        
        // Optionnels
        if let lieu = payload.lieu {
            appendFormField(name: "lieu", value: lieu)
        }
        if let difficulte = payload.difficulte {
            appendFormField(name: "difficulte", value: difficulte)
        }
        if let niveau = payload.niveau {
            appendFormField(name: "niveau", value: niveau)
        }
        if let capacite = payload.capacite {
            appendFormField(name: "capacite", value: String(capacite))
        }
        if let prix = payload.prix {
            appendFormField(name: "prix", value: String(prix))
        }
        if let campingId = payload.campingId {
            appendFormField(name: "campingId", value: campingId)
        }
        
        // Itinéraire JSON
        appendFormField(name: "itineraire", value: payload.itineraireJSON)
        
        // Camping JSON (optionnel)
        if let campingJSON = payload.campingJSON {
            appendFormField(name: "camping", value: campingJSON)
        }
        
        // Photo URL (optionnel, comme fallback si tu veux la stocker côté backend)
        if let photoURL = payload.photoURL, !photoURL.isEmpty {
            appendFormField(name: "photo", value: photoURL)
        }
        
        // Fin du body
        if let closing = "--\(boundary)--\r\n".data(using: .utf8) {
            body.append(closing)
        }
        
        request.httpBody = body
        
        #if DEBUG
        print("[HTTP] POST \(url.absoluteString) (createSortie)")
        print("[HTTP] Headers (sortie): \(request.allHTTPHeaderFields ?? [:])")
        if let bodyString = String(data: body, encoding: .utf8) {
            print("[HTTP] Multipart body (truncated):")
            print(bodyString.prefix(800))
        }
        #endif
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SortieServiceError.invalidResponse
        }
        
        #if DEBUG
        print("[HTTP] createSortieMultipart status: \(http.statusCode)")
        print("[HTTP] createSortieMultipart raw response: \(String(data: data, encoding: .utf8) ?? "no body")")
        #endif
        
        if http.statusCode == 401 {
            throw SortieServiceError.unauthorized
        }
        
        guard (200..<300).contains(http.statusCode) else {
            throw SortieServiceError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode(SortieResponse.self, from: data)
        } catch {
            throw SortieServiceError.decodingError
        }
    }
    
    // MARK: - OpenRouteService
    
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
        let full = base + profile + "/geojson"
        return URL(string: full)!
    }
    
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
        request.setValue("application/json, application/geo+json, application/geojson", forHTTPHeaderField: "Accept")
        
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
        
        if let fc = try? decoder.decode(ORSFeatureCollection.self, from: data),
           let feature = fc.features.first {
            
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
        
        if let routes = try? decoder.decode(ORSRoutesWrapper.self, from: data),
           let route = routes.routes.first {
            
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
        
        throw SortieServiceError.decodingError
    }
}
