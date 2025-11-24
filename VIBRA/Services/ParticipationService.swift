import Foundation

final class ParticipationService {
    static let shared = ParticipationService()
    private init() {}

    private var baseURL: String { Constants.baseURL }

    // MARK: - Création de participation

    /// Créer une participation EN_ATTENTE pour une sortie
    func createParticipation(userId: String, sortieId: String) async throws -> Participation {
        let urlString = "\(baseURL)/participations"
        guard let url = URL(string: urlString) else { throw ParticipationError.badURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        guard let token = try? KeychainManager.shared.getJWT() else { throw ParticipationError.noToken }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "sortieId": sortieId,
            "userId": userId,
            "status": "EN_ATTENTE"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ParticipationError.invalidResponse(-1, "no http response")
        }

        let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
        print("🛰 createParticipation HTTP \(http.statusCode)")
        print("🧪 RAW JSON:", bodyString)

        guard (200...299).contains(http.statusCode) else {
            throw ParticipationError.invalidResponse(http.statusCode, bodyString)
        }

        // NE PAS décoder ici, la forme ne correspond pas au modèle Participation
        let user = ParticipationUser(id: userId, email: nil)
        let sortie = ParticipationSortie(id: sortieId, titre: nil, description: nil, createurId: nil)
        let participation = Participation(
            id: nil,
            user: user,
            sortie: sortie,
            status: "EN_ATTENTE",
            createdAt: nil,
            updatedAt: nil
        )
        return participation
    }

    // MARK: - Liste des participations d'une sortie

    /// GET /participations?sortieId=...
    func listParticipations(sortieId: String) async throws -> [Participation] {
        guard var components = URLComponents(string: "\(baseURL)/participations") else {
            throw ParticipationError.badURL
        }
        components.queryItems = [
            URLQueryItem(name: "sortieId", value: sortieId)
        ]
        guard let url = components.url else {
            throw ParticipationError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        if let token = try? KeychainManager.shared.getJWT() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ParticipationError.invalidResponse(-1, "no http response")
        }

        let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
        print("🛰 listParticipations(\(sortieId)) HTTP \(http.statusCode)")
        print("🧪 RAW JSON:", bodyString.prefix(500), "…")

        if http.statusCode == 304 {
            print("ℹ️ 304 Not Modified → retour []")
            return []
        }

        guard (200...299).contains(http.statusCode) else {
            throw ParticipationError.invalidResponse(http.statusCode, bodyString)
        }

        do {
            let participations = try JSONDecoder().decode([Participation].self, from: data)
            print("✅ \(participations.count) participations décodées pour sortieId \(sortieId)")
            return participations
        } catch {
            print("❌ listParticipations decoding error:", error)
            throw ParticipationError.decoding(error)
        }
    }

    // MARK: - Mise à jour du statut

    /// PATCH /participations/{id}/status  body: { "status": "ACCEPTEE" | "EN_ATTENTE" | "REFUSEE" }
    func updateParticipationStatus(id: String, status: String) async throws {
        let urlString = "\(baseURL)/participations/\(id)/status"
        guard let url = URL(string: urlString) else { throw ParticipationError.badURL }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        guard let token = try? KeychainManager.shared.getJWT() else { throw ParticipationError.noToken }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "status": status
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ParticipationError.invalidResponse(-1, "no http response")
        }

        let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
        print("🛰 updateParticipationStatus(\(id)) HTTP \(http.statusCode)")
        print("🧪 RAW JSON:", bodyString.prefix(500), "…")

        guard (200...299).contains(http.statusCode) else {
            throw ParticipationError.invalidResponse(http.statusCode, bodyString)
        }

        // NE PAS décoder ici : la réponse renvoie userId/sortieId en string, pas en objet.
        // On se contente de savoir que la MAJ a réussi (200).
    }
    /// GET /participations/user/{userId}
        /// Récupère toutes les participations d'un utilisateur (tous statuts)
        func listParticipationsForUser(userId: String) async throws -> [Participation] {
            let urlString = "\(baseURL)/participations/user/\(userId)"
            guard let url = URL(string: urlString) else { throw ParticipationError.badURL }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.cachePolicy = .reloadIgnoringLocalCacheData

            // route publique, mais on peut envoyer le token si dispo
            if let token = try? KeychainManager.shared.getJWT() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw ParticipationError.invalidResponse(-1, "no http response")
            }

            let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
            print("🛰 listParticipationsForUser(\(userId)) HTTP \(http.statusCode)")
            print("🧪 RAW JSON:", bodyString.prefix(500), "…")

            guard (200...299).contains(http.statusCode) else {
                throw ParticipationError.invalidResponse(http.statusCode, bodyString)
            }


            do {
                let decoder = JSONDecoder()
                let dtos = try decoder.decode([UserParticipationDTO].self, from: data)

                // Mapper vers ton modèle Participation pour que le reste du code ne change pas
                let participations: [Participation] = dtos.map { dto in
                    let user = ParticipationUser(id: dto.userId, email: nil)
                    return Participation(
                        id: dto.id,
                        user: user,
                        sortie: dto.sortieId,
                        status: dto.status,
                        createdAt: dto.createdAt,
                        updatedAt: dto.updatedAt
                    )
                }

                print("✅ \(participations.count) participations (user) mappées pour userId \(userId)")
                return participations
            } catch {
                print("❌ listParticipationsForUser decoding error:", error)
                throw ParticipationError.decoding(error)
            }
        }
    /// Nouvelle fonction : crée une participation **ACCEPTEE** pour le créateur
        /// sans toucher à createParticipation existant.
        func createAcceptedParticipationForCreator(userId: String, sortieId: String) async throws -> Participation {
            let urlString = "\(baseURL)/participations"
            guard let url = URL(string: urlString) else { throw ParticipationError.badURL }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            guard let token = try? KeychainManager.shared.getJWT() else { throw ParticipationError.noToken }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let body: [String: Any] = [
                "sortieId": sortieId,
                "userId": userId,
                "status": "ACCEPTEE"
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw ParticipationError.invalidResponse(-1, "no http response")
            }

            let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
            print("🛰 createAcceptedParticipationForCreator HTTP \(http.statusCode)")
            print("🧪 RAW JSON:", bodyString)

            guard (200...299).contains(http.statusCode) else {
                throw ParticipationError.invalidResponse(http.statusCode, bodyString)
            }

            // On reconstruit un modèle Participation cohérent
            let user = ParticipationUser(id: userId, email: nil)
            let sortie = ParticipationSortie(id: sortieId, titre: nil, description: nil, createurId: nil)
            let participation = Participation(
                id: nil,
                user: user,
                sortie: sortie,
                status: "ACCEPTEE",
                createdAt: nil,
                updatedAt: nil
            )
            return participation
        }
}
