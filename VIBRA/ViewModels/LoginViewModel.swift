//
//  LoginViewModel.swift
//  VIBRA
//

import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isLoggedIn = false
    
    // MARK: - Login (JWT toujours sauvegardé)
    func login(stayConnected: Bool) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await AuthService.shared.login(email: email, password: password)
            print("✅ Token reçu : \(response.access_token)")
            
            // ✅ Sauvegarder le JWT systématiquement dans le Keychain
            do {
                try KeychainManager.shared.saveJWT(token: response.access_token)
            } catch {
                print("⚠️ Erreur sauvegarde JWT dans Keychain: \(error)")
            }
            
            // Si tu veux garder "stayConnected" pour autre chose (par ex. une préférence utilisateur),
            // tu peux encore le stocker dans UserDefaults ici si nécessaire.
            
            // Marquer l'utilisateur comme connecté
            isLoggedIn = true
        } catch {
            errorMessage = "Email ou mot de passe incorrect."
            print("❌ Login error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Vérifier si token existe déjà
    func checkIfAlreadyLoggedIn() {
        if let _ = try? KeychainManager.shared.getJWT() {
            isLoggedIn = true
        }
    }
}
