import Foundation

struct Participation: Codable, Identifiable {
    let id: String
    /// Identifiant brut de l'utilisateur (toujours rempli si possible)
    let userId: String?
    /// Détails éventuels de l'utilisateur quand le backend renvoie un objet
    let user: ParticipationUser?
    let sortieId: String?
    let status: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId
        case sortieId
        case status
        case createdAt
        case updatedAt
    }

    init(
        id: String,
        userId: String?,
        user: ParticipationUser?,
        sortieId: String?,
        status: String?,
        createdAt: String?,
        updatedAt: String?
    ) {
        self.id = id
        self.userId = userId
        self.user = user
        self.sortieId = sortieId
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // _id est requis côté Mongo, on le force en String
        self.id = try container.decode(String.self, forKey: .id)

        // sortieId peut être renvoyé comme string simple ou comme ObjectId string
        self.sortieId = try? container.decode(String.self, forKey: .sortieId)

        self.status = try? container.decode(String.self, forKey: .status)
        self.createdAt = try? container.decode(String.self, forKey: .createdAt)
        self.updatedAt = try? container.decode(String.self, forKey: .updatedAt)

        // Gestion flexible de userId :
        //  - soit un string simple => "6709d45e..."
        //  - soit un objet => { "_id": "…", "name": "…", "email": "…" }
        if let userIdString = try? container.decode(String.self, forKey: .userId) {
            self.userId = userIdString
            self.user = nil
        } else if let userObject = try? container.decode(ParticipationUser.self, forKey: .userId) {
            self.user = userObject
            self.userId = userObject.id
        } else {
            self.userId = nil
            self.user = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(sortieId, forKey: .sortieId)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)

        // Par défaut, on renvoie plutôt l'id (string) vers le backend
        if let uid = userId {
            try container.encode(uid, forKey: .userId)
        } else if let u = user {
            try container.encode(u, forKey: .userId)
        }
    }
}

/// Représente l'objet renvoyé quand userId est peuplé (populate Mongoose)
struct ParticipationUser: Codable, Identifiable {
    let id: String
    let name: String?
    let email: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case email
    }
}

enum ParticipationError: Error, CustomStringConvertible {
    case badURL
    case noToken
    case invalidResponse(Int, String)
    case decoding(Error)
    case network(Error)

    var description: String {
        switch self {
        case .badURL: return "URL invalide"
        case .noToken: return "Token manquant"
        case .invalidResponse(let code, let body): return "Réponse serveur invalide (code: \(code)) body: \(body)"
        case .decoding(let e): return "Erreur de décodage: \(e.localizedDescription)"
        case .network(let e): return "Erreur réseau: \(e.localizedDescription)"
        }
    }
}
