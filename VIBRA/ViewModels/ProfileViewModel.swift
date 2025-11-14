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
            // Récupérer le JWT
            let token = try KeychainManager.shared.getJWT()
            
            // Extraire l'ID utilisateur du payload
            guard let userId = token.getUserIdFromJWT() else {
                errorMessage = "ID utilisateur invalide"
                isLoading = false
                return
            }
            
            // Appeler l'API
            let fetchedUser = try await AuthService.shared.getUser(byId: userId)
            self.user = fetchedUser
            
        } catch {
            errorMessage = "Impossible de charger le profil"
            print("❌ Profile fetch error: \(error)")
        }
        
        isLoading = false
    }
}

// Extension pour décoder l'ID depuis le JWT
extension String {
    func getUserIdFromJWT() -> String? {
        let segments = self.split(separator: ".")
        guard segments.count > 1 else { return nil }
        var base64 = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let userId = json["sub"] as? String else { return nil }
        return userId
    }
}

