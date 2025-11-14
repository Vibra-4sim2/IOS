//
//  ProfileUpdateViewModel.swift
//  VIBRA
//
//  Created by mac book pro on 11/10/25.
//

import Foundation
import Combine


final class ProfileUpdateViewModel: ObservableObject {
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var gender = ""
    @Published var email = ""
    @Published var password = "" // Mot de passe optionnel
    private var oldPassword = ""

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private var userId: String?

    func loadUser() async {
        isLoading = true
        errorMessage = nil
        do {
            guard let token = try? KeychainManager.shared.getJWT(),
                  let id = token.getUserIdFromJWT() else {
                errorMessage = "Utilisateur invalide"
                isLoading = false
                return
            }
            self.userId = id
            let user = try await AuthService.shared.getUser(byId: id)
            self.firstName = user.firstName
            self.lastName = user.lastName
            self.gender = user.gender
            self.email = user.email
            self.oldPassword = "" // stocker le mot de passe actuel si besoin
        } catch {
            errorMessage = "Impossible de charger les données"
        }
        isLoading = false
    }

    func updateUser() async {
        guard let userId = userId else { return }
        isLoading = true
        errorMessage = nil
        successMessage = nil
        do {
            let request = UpdateUserRequest(
                firstName: firstName,
                lastName: lastName,
                gender: gender,
                email: email,
                password: password.isEmpty ? oldPassword : password
            )
            let _ = try await AuthService.shared.updateUser(userId: userId, updatedUser: request)
            successMessage = "Profil mis à jour avec succès !"
        } catch {
            errorMessage = "Erreur lors de la mise à jour"
            print("❌ Update error: \(error)")
        }
        isLoading = false
    }
}
