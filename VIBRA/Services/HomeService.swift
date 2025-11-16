// HomeService.swift
// VIBRA

import Foundation

enum APIError: Error {
    case badURL
    case invalidResponse(Int)
    case decodingFailed(Error)
    case requestFailed(Error)
}

final class HomeService {
    static let shared = HomeService()
    private init() {}

    private var baseURL: String { Constants.baseURL }

    // Récupérer toutes les sorties
    func fetchRides() async throws -> [Ride] {
        let urlString = "\(baseURL)/sorties"
        print("🌐 HomeService: Fetching rides from \(urlString)")
        guard let url = URL(string: urlString) else {
            print("❌ HomeService: Invalid URL - \(urlString)")
            throw APIError.badURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData  // ⚡ Force nouvelle requête (pas de cache 304)
        request.timeoutInterval = 30

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse(-1) }
            print("📡 HomeService: Response status code - \(http.statusCode)")
            print("📦 HomeService: Data size - \(data.count) bytes")
            
            // Vérifier le code de statut (accepter 200-299)
            guard (200...299).contains(http.statusCode) else {
                print("❌ HomeService: Invalid status code - \(http.statusCode)")
                throw APIError.invalidResponse(http.statusCode)
            }

            // Print raw JSON for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 HomeService: Raw JSON response - \(jsonString.prefix(500))...")
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let rides = try decoder.decode([Ride].self, from: data)
            print("✅ HomeService: Successfully decoded \(rides.count) rides")
            return rides
        } catch let error as DecodingError {
            print("❌ HomeService: Decoding error - \(error)")
            throw APIError.decodingFailed(error)
        } catch {
            print("❌ HomeService: Request failed - \(error)")
            throw APIError.requestFailed(error)
        }
    }

    func fetchUser(id: String) async throws -> User {
        let urlString = "\(baseURL)/user/\(id)"  // ⚡ Changé de /users/ à /user/
        print("👤 HomeService: Fetching user from \(urlString)")
        guard let url = URL(string: urlString) else { 
            print("❌ HomeService: Invalid user URL - \(urlString)")
            throw APIError.badURL 
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse(-1) }
            print("📡 HomeService: User response status - \(http.statusCode)")
            guard (200...299).contains(http.statusCode) else { 
                print("❌ HomeService: Invalid user status code - \(http.statusCode)")
                throw APIError.invalidResponse(http.statusCode) 
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                print("👤 HomeService: User JSON - \(jsonString.prefix(200))...")
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let user = try decoder.decode(User.self, from: data)
            print("✅ HomeService: Successfully decoded user - \(user.firstName) \(user.lastName)")
            return user
        } catch let error as DecodingError {
            print("❌ HomeService: User decoding error - \(error)")
            throw APIError.decodingFailed(error)
        } catch {
            print("❌ HomeService: User request failed - \(error)")
            throw APIError.requestFailed(error)
        }
    }

    func fetchRidesWithCreators() async throws -> [RideWithCreator] {
        let rides = try await fetchRides()
        print("🔄 HomeService: Starting to fetch creators for \(rides.count) rides...")
        var results = [RideWithCreator?](repeating: nil, count: rides.count)

        try await withThrowingTaskGroup(of: (Int, RideWithCreator?).self) { group in
            for (index, ride) in rides.enumerated() {
                group.addTask {
                    print("🔍 HomeService: Processing ride #\(index) - \(ride.titre)")
                    
                    // If the ride already has an embedded creator, use it
                    if let embedded = ride.creator {
                        print("✅ HomeService: Ride #\(index) has embedded creator - \(embedded.firstName)")
                        return (index, RideWithCreator(ride: ride, creator: embedded))
                    }

                    // Otherwise, if we have an id, fetch the user
                    if let creatorId = ride.createurId {
                        print("🔍 HomeService: Ride #\(index) has createurId - \(creatorId), fetching user...")
                        do {
                            let user = try await self.fetchUser(id: creatorId)
                            print("✅ HomeService: Ride #\(index) creator fetched - \(user.firstName) \(user.lastName)")
                            return (index, RideWithCreator(ride: ride, creator: user))
                        } catch {
                            print("❌ HomeService: Failed to fetch creator for ride #\(index) - \(error)")
                            return (index, RideWithCreator(ride: ride, creator: nil))
                        }
                    } else {
                        print("⚠️ HomeService: Ride #\(index) has no createurId")
                    }

                    // No creator info available
                    return (index, RideWithCreator(ride: ride, creator: nil))
                }
            }

            for try await (index, item) in group {
                results[index] = item
            }
        }

        let finalResults = results.compactMap { $0 }
        print("✅ HomeService: Completed fetching creators. Total: \(finalResults.count) rides with creators")
        return finalResults
    }
}
