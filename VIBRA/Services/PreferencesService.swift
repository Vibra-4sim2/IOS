//
//  PreferencesService.swift
//  VIBRA
//

import Foundation
import Combine

// NOTE:
// On crée un payload séparé pour l'envoi afin d'exclure volontairement `user` et `_id`
// — on laisse le userId dans le path (POST /preferences/{userId}).
private struct PreferencesPayload: Encodable {
    var level: Level?

    // Cycling
    var cyclingType: CyclingType?
    var cyclingFrequency: CyclingFrequency?
    var cyclingDistance: CyclingDistance?
    var cyclingGroupInterest: Bool?

    // Hike
    var hikeType: HikeType?
    var hikeDuration: HikeDuration?
    var hikePreference: HikePreference?

    // Camping
    var campingPractice: Bool?
    var campingType: CampingType?
    var campingDuration: CampingDuration?

    var onboardingComplete: Bool?
}

class PreferencesService {
    static let shared = PreferencesService()
    private let baseURL = "\(Constants.baseURL)/preferences"

    private init() {}

    func fetchPreferences(userId: String, token: String) -> AnyPublisher<Preferences, Error> {
        guard let url = URL(string: "\(baseURL)/\(userId)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        #if DEBUG
        print("🔵 Fetch Preferences request: GET \(request.url?.absoluteString ?? "")")
        print("🔵 Headers: \(request.allHTTPHeaderFields ?? [:])")
        #endif

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let http = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                let bodyText = String(data: data, encoding: .utf8) ?? ""
                guard (200..<300).contains(http.statusCode) else {
                    throw NSError(domain: "PreferencesService",
                                  code: http.statusCode,
                                  userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(bodyText)"])
                }
                return data
            }
            .decode(type: Preferences.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }

    // POST create/update preferences at /preferences/{userId}
    // We send a payload that does NOT include `user` or `_id`.
    func savePreferences(userId: String, preferences: Preferences, token: String) -> AnyPublisher<Preferences, Error> {
        guard let url = URL(string: "\(baseURL)/\(userId)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST" // backend expects POST for create/upsert
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Build payload that intentionally excludes `user` and `_id`
        let payload = PreferencesPayload(
            level: preferences.level,
            cyclingType: preferences.cyclingType,
            cyclingFrequency: preferences.cyclingFrequency,
            cyclingDistance: preferences.cyclingDistance,
            cyclingGroupInterest: preferences.cyclingGroupInterest,
            hikeType: preferences.hikeType,
            hikeDuration: preferences.hikeDuration,
            hikePreference: preferences.hikePreference,
            campingPractice: preferences.campingPractice,
            campingType: preferences.campingType,
            campingDuration: preferences.campingDuration,
            onboardingComplete: preferences.onboardingComplete
        )

        do {
            let encoder = JSONEncoder()
            let bodyData = try encoder.encode(payload)
            request.httpBody = bodyData

            #if DEBUG
            if let bodyStr = String(data: bodyData, encoding: .utf8) {
                print("🟢 Save Preferences request: POST \(request.url?.absoluteString ?? "")")
                print("🟢 Headers: \(request.allHTTPHeaderFields ?? [:])")
                print("🟢 Body: \(bodyStr)")
            }
            #endif
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let http = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                let bodyText = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                guard (200..<300).contains(http.statusCode) else {
                    throw NSError(domain: "PreferencesService",
                                  code: http.statusCode,
                                  userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(bodyText)"])
                }
                #if DEBUG
                print("🟢 Save Preferences response HTTP \(http.statusCode): \(bodyText)")
                #endif
                return data
            }
            .decode(type: Preferences.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}
