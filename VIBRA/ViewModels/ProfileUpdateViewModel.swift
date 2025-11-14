//
//  ProfileUpdateViewModel.swift
//  VIBRA
//
//  Created by mac book pro on 11/10/25.
//

import Foundation
import UIKit
import Combine


final class ProfileUpdateViewModel: ObservableObject {
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var email = ""
    @Published var password = "" // Mot de passe optionnel

    @Published var birthday: Date? = nil
    @Published var avatarURL: String? = nil

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private var userId: String?

    // Date formatter used when sending to backend (yyyy-MM-dd)
    private let serverDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

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
            self.email = user.email
            self.avatarURL = user.avatar

            // Parse birthday from user.birthday (try ISO8601 then yyyy-MM-dd)
            if let b = user.birthday {
                if let isoDate = ISO8601DateFormatter().date(from: b) {
                    self.birthday = isoDate
                } else if let dateFromServer = parseServerBirthday(b) {
                    self.birthday = dateFromServer
                } else {
                    self.birthday = nil
                }
            } else {
                self.birthday = nil
            }
        } catch {
            errorMessage = "Impossible de charger les données (\(error.localizedDescription))"
            print("❌ ProfileUpdate loadUser error: \(error)")
        }
        isLoading = false
    }

    private func parseServerBirthday(_ str: String) -> Date? {
        // try yyyy-MM-dd
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.date(from: str)
    }

    func updateUser() async {
        guard let userId = userId else {
            errorMessage = "Utilisateur introuvable"
            return
        }
        isLoading = true
        errorMessage = nil
        successMessage = nil
        do {
            let birthdayString = birthday.map { serverDateFormatter.string(from: $0) }
            let request = UpdateUserRequest(
                firstName: firstName,
                lastName: lastName,
                email: email,
                birthday: birthdayString,
                avatar: nil,
                password: password.isEmpty ? nil : password
            )
            let _ = try await AuthService.shared.updateUser(userId: userId, updatedUser: request)
            successMessage = "Profil mis à jour avec succès !"
        } catch {
            errorMessage = "Erreur lors de la mise à jour (\(error.localizedDescription))"
            print("❌ Update error: \(error)")
        }
        isLoading = false
    }

    // Upload avatar image (UIImage) — calls AuthService.uploadAvatar(...) to send multipart/form-data
    func uploadAvatar(uiImage: UIImage) async {
        guard let userId = userId else {
            errorMessage = "Utilisateur introuvable"
            return
        }
        isLoading = true
        errorMessage = nil
        successMessage = nil

        // Convert UIImage to JPEG data
        guard let imageData = uiImage.jpegData(compressionQuality: 0.85) else {
            errorMessage = "Impossible de préparer l'image"
            isLoading = false
            return
        }

        do {
            // AuthService.added function: uploadAvatar(userId:imageData:fileName:mimeType:)
            let updatedUser = try await AuthService.shared.uploadAvatar(userId: userId, imageData: imageData, fileName: "avatar.jpg", mimeType: "image/jpeg")
            // Mise à jour locale
            self.avatarURL = updatedUser.avatar
            self.firstName = updatedUser.firstName
            self.lastName = updatedUser.lastName
            self.email = updatedUser.email
            if let b = updatedUser.birthday {
                // try parse as yyyy-MM-dd
                if let d1 = serverDateFormatter.date(from: b) {
                    self.birthday = d1
                } else if let d2 = ISO8601DateFormatter().date(from: b) {
                    self.birthday = d2
                }
            }
            successMessage = "Avatar mis à jour"
        } catch {
            errorMessage = "Erreur upload avatar : \(error.localizedDescription)"
            print("❌ uploadAvatar error: \(error)")
        }

        isLoading = false
    }
}
