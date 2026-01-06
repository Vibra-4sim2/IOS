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
            
            // Initialize conversation socket
            if let userId = JWTHelper.extractUserId(from: response.access_token) {
                ConversationSocketManager.shared.connect(token: response.access_token, userId: userId)
            }
            
            // Request notification permission after successful login
            LocalNotificationManager.shared.requestPermission { granted in
                if granted {
                    print("✅ Notification permission granted")
                } else {
                    print("⚠️ Notification permission denied - notifications won't appear")
                }
            }
            
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
        if let token = try? KeychainManager.shared.getJWT() {
            isLoggedIn = true
            
            // Initialize conversation socket if already logged in
            if let userId = JWTHelper.extractUserId(from: token) {
                ConversationSocketManager.shared.connect(token: token, userId: userId)
            }
        }
    }
}
