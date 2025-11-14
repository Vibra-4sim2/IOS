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
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchUser() async {
        isLoading = true
        errorMessage = nil

        do {
            // Récupérer le JWT (propager l'erreur si introuvable)
            let token: String
            do {
                token = try KeychainManager.shared.getJWT()
            } catch {
                throw ProfileError.missingToken(error)
            }

            // Extraire l'ID utilisateur depuis le token (plus robuste)
            guard let userId = token.getUserIdFromJWT() else {
                throw ProfileError.invalidTokenPayload
            }

            // Appeler l'API (AuthService reste inchangé)
            let fetchedUser = try await AuthService.shared.getUser(byId: userId)
            self.user = fetchedUser
            self.errorMessage = nil

        } catch let pError as ProfileError {
            // Erreurs contrôlées depuis ce ViewModel
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
            // Erreurs provenant d'AuthService ou autres (URLError, decoding, etc.)
            errorMessage = "Impossible de charger le profil. (\(error.localizedDescription))"
            print("❌ Profile fetch error: \(error)")
        }

        isLoading = false
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
