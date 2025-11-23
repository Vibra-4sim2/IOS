//
//  ProfileViewModel.swift
//  VIBRA
//
//  Created by mac book pro on 11/9/25.
//

import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    // MARK: - Inputs
    let viewedUserId: String?   // nil => current user profile

    // MARK: - Segments
    enum Segment {
        case mesSorties
        case creees
        case publications
    }

    @Published var selectedSegment: Segment = .mesSorties

    // MARK: - Published state
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Follow stats
    @Published var followersCount: Int = 0
    @Published var followingCount: Int = 0
    @Published var isFollowing: Bool = false
    @Published var isFollowLoading: Bool = false

    // Content counts
    @Published var sortiesCount: Int = 0
    @Published var publicationsCount: Int = 0

    // Content lists
    @Published var rides: [RideWithCreator] = []
    @Published var createdRides: [RideWithCreator] = []
    @Published var publications: [PublicationResponse] = []

    init(viewedUserId: String? = nil) {
        self.viewedUserId = viewedUserId
    }

    // MARK: - Public API
    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let userId = try await resolveUserId()
            let fetchedUser = try await AuthService.shared.getUser(byId: userId)
            self.user = fetchedUser

            // Parallel: follow stats, is-following, content lists
            async let statsTask = AuthService.shared.fetchFollowStats(for: userId)
            async let isFollowingTask = (try? AuthService.shared.checkIsFollowing(userId: userId))
            async let ridesTask = HomeService.shared.fetchRidesWithCreators()
            async let publicationsTask = PublicationService.shared.getPublicationsByAuthor(authorId: userId)

            let stats = try await statsTask
            self.followersCount = stats.followersCount
            self.followingCount = stats.followingCount

            if let isFollow = try await isFollowingTask {
                self.isFollowing = isFollow
            } else {
                self.isFollowing = false
            }

            let allRides = try await ridesTask
            let userRides = allRides.filter { $0.creator?.id == userId }
            self.rides = userRides
            self.createdRides = userRides
            self.sortiesCount = userRides.count

            switch await publicationsTask {
            case .success(let list):
                self.publications = list
                self.publicationsCount = list.count
            case .failure:
                self.publications = []
                self.publicationsCount = 0
            }
        } catch let pError as ProfileError {
            switch pError {
            case .missingToken:
                errorMessage = "Token introuvable. Veuillez vous reconnecter."
            case .invalidTokenPayload:
                errorMessage = "Jeton invalide — impossible d'extraire l'ID utilisateur."
            case .other(let underlying):
                errorMessage = "Erreur: \(underlying.localizedDescription)"
            }
            print("❌ Profile fetch error (ProfileError): \(pError)")
        } catch {
            errorMessage = "Impossible de charger le profil. (\(error.localizedDescription))"
            print("❌ Profile fetch error: \(error)")
        }
    }

    func toggleFollow() async {
        guard let targetId = viewedUserId ?? user?.id else { return }
        isFollowLoading = true
        defer { isFollowLoading = false }
        do {
            if isFollowing {
                try await AuthService.shared.unfollowUser(userId: targetId)
                isFollowing = false
                followersCount = max(0, followersCount - 1)
            } else {
                try await AuthService.shared.followUser(userId: targetId)
                isFollowing = true
                followersCount += 1
            }
        } catch {
            print("❌ toggleFollow error: \(error)")
        }
    }

    // MARK: - Helpers
    private func resolveUserId() async throws -> String {
        if let id = viewedUserId { return id }
        do {
            let token = try KeychainManager.shared.getJWT()
            if let userId = token.getUserIdFromJWT() {
                return userId
            }
            throw ProfileError.invalidTokenPayload
        } catch {
            throw ProfileError.missingToken(error)
        }
    }
}

// MARK: - Erreurs spécifiques au ProfileViewModel
enum ProfileError: Error, CustomStringConvertible {
    case missingToken(Error? = nil)
    case invalidTokenPayload
    case other(Error)

    var description: String {
        switch self {
        case .missingToken(let e): return "missingToken (\(e?.localizedDescription ?? "no underlying error"))"
        case .invalidTokenPayload: return "invalidTokenPayload"
        case .other(let e): return "other (\(e.localizedDescription))"
        }
    }
}

// Extension pour décoder l'ID depuis le JWT (plus robuste)
extension String {
    func getUserIdFromJWT() -> String? {
        let segments = self.split(separator: ".")
        guard segments.count > 1 else { return nil }

        var base64 = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }

        guard let data = Data(base64Encoded: base64) else { return nil }
        guard let jsonObj = try? JSONSerialization.jsonObject(with: data) else { return nil }

        // Try to cast to dictionary
        guard let payload = jsonObj as? [String: Any] else { return nil }

        // Common keys where user id may appear
        let candidateKeys = ["sub", "id", "userId", "user_id", "uid"]

        for key in candidateKeys {
            if let value = payload[key] {
                if let s = value as? String, !s.isEmpty { return s }
                if let n = value as? Int { return String(n) }
                if let n = value as? Int64 { return String(n) }
            }
        }

        // Sometimes the token payload contains nested objects like "user": { "id": ... }
        if let userObj = payload["user"] as? [String: Any] {
            for key in ["id", "userId", "user_id"] {
                if let value = userObj[key] {
                    if let s = value as? String, !s.isEmpty { return s }
                    if let n = value as? Int { return String(n) }
                }
            }
        }

        // No id found
        return nil
    }
}
