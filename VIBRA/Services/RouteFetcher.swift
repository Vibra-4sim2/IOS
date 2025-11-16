// filepath: /Users/mohamedmami/Documents/IOS/VIBRA/Services/RouteFetcher.swift
import Foundation
import CoreLocation

enum RouteFetcherError: Error {
    case missingKey
    case badResponse(Int)
    case decodingError(Error)
    case noGeometry
}

struct RouteFetcher {
    // Use API key from Constants
    static func fetchRouteCoordinates(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D,
        profile: String
    ) async throws -> ([CLLocationCoordinate2D], Double?) {
        let key = Constants.openRouteApiKey
        guard !key.isEmpty else { throw RouteFetcherError.missingKey }

        guard let url = URL(string: "https://api.openrouteservice.org/v2/directions/\(profile)/geojson") else {
            throw RouteFetcherError.badResponse(-1)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(key, forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "coordinates": [
                [from.longitude, from.latitude],
                [to.longitude, to.latitude]
            ],
            "instructions": false
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? -1
        guard (200...299).contains(status) else { throw RouteFetcherError.badResponse(status) }

        struct GeoJSON: Decodable {
            struct Feature: Decodable {
                struct Geometry: Decodable { let coordinates: [[Double]] }
                let geometry: Geometry
                struct Properties: Decodable {
                    struct Summary: Decodable { let distance: Double? }
                    let summary: Summary?
                }
                let properties: Properties?
            }
            let features: [Feature]
        }

        do {
            let geo = try JSONDecoder().decode(GeoJSON.self, from: data)
            guard let first = geo.features.first else { throw RouteFetcherError.noGeometry }
            let coords = first.geometry.coordinates.map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
            let distance = first.properties?.summary?.distance
            return (coords, distance)
        } catch {
            throw RouteFetcherError.decodingError(error)
        }
    }
}
