//
//  RegisterViewModel.swift
//  VIBRA
//
//  Created by mac book pro on 11/7/25.
//

import Foundation
import Combine

@MainActor
final class RegisterViewModel: ObservableObject {
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var gender = ""                // ✔ obligatoire
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""

    @Published var birthday: String? = nil    // ✔ nouveau champ DTO
    @Published var avatar: String? = nil      // ✔ optionnel
    @Published var role: String? = nil        // ✔ optionnel

    @Published var agreeTerms = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isRegistered = false
    @Published var isLoggedIn = false          // <-- utilisé pour la navigation automatique
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    // MARK: - PUBLIC
    func register() {
        Task { await registerAsync() }
    }
    
    // MARK: - PRIVATE
    private func validateFields() -> String? {
        if firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Veuillez entrer votre nom et prénom."
        }

        if gender.isEmpty {
            return "Veuillez sélectionner votre genre."
        }

        if !email.contains("@") {
            return "Veuillez entrer un email valide."
        }

        if password.count < 6 {
            return "Le mot de passe doit contenir au moins 6 caractères."
        }

        if password != confirmPassword {
            return "Les mots de passe ne correspondent pas."
        }

        if !agreeTerms {
            return "Vous devez accepter les conditions."
        }

        return nil
    }

    // MARK: - REGISTER LOGIC
    func registerAsync() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Validation locale
        if let error = validateFields() {
            alertTitle = "Erreur"
            alertMessage = error
            showAlert = true
            return
        }
        
        do {
            let user = try await AuthService.shared.register(
                firstName: firstName,
                lastName: lastName,
                gender: gender,
                email: email,
                password: password,
                birthday: birthday,
                avatar: avatar,
                role: role
            )
            
            print("✅ User created: \(user.email)")
            isRegistered = true
            
            // Après un register réussi, on fait un login automatique pour récupérer le JWT
            do {
                let response = try await AuthService.shared.login(email: email, password: password)
                
                // Sauvegarder le jwt dans le Keychain
                do {
                    try KeychainManager.shared.saveJWT(token: response.access_token)
                    print("🔐 JWT sauvegardé dans le Keychain")
                } catch {
                    // Sauvegarde du token échouée : on avertit mais on peut quand même considérer l'user comme enregistré
                    print("⚠️ Erreur lors de la sauvegarde du JWT dans le Keychain: \(error)")
                    alertTitle = "Attention"
                    alertMessage = "Inscription réussie mais impossible de sauvegarder la session. Veuillez vous connecter manuellement."
                    showAlert = true
                    // Si tu veux empêcher la navigation automatique en cas d'échec du Keychain, retourne ici.
                    // return
                }
                
                // Marquer l'utilisateur connecté -> déclenchera la navigation automatique côté vue
                isLoggedIn = true
                
                // Optionnel : vider le mot de passe en mémoire
                password = ""
                confirmPassword = ""
                
            } catch {
                // Si le login automatique échoue après le register
                print("❌ Login after register failed: \(error)")
                alertTitle = "Inscription réussie"
                alertMessage = "Connexion automatique impossible. Veuillez vous connecter manuellement."
                showAlert = true
            }
            
        } catch {
            // Erreur lors du register
            print("❌ Register error: \(error)")
            errorMessage = "Erreur lors de l'inscription."
            alertTitle = "Registration Failed"
            alertMessage = parseErrorMessage(error) ?? errorMessage ?? "An unknown error occurred."
            showAlert = true
        }
    }
    
    // Helper pour tenter d'extraire un message d'erreur lisible (selon ton AuthService)
    private func parseErrorMessage(_ error: Error) -> String? {
        // Si AuthService renvoie un type custom contenant une réponse, tu peux décoder ici.
        // Exemple générique :
        // if let apiError = error as? APIError { return apiError.message }
        // Sinon, retourne error.localizedDescription
        return (error as NSError).localizedDescription
    }
}
