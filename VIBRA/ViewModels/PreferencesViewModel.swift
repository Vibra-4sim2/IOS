//
//  PreferencesViewModel.swift
//  VIBRA
//

import Foundation
import Combine
import SwiftUI

@MainActor
class PreferencesViewModel: ObservableObject {
    @Published var preferences = Preferences()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var navigateToHome = false  // Pour navigation après save

    private var cancellables = Set<AnyCancellable>()

    func loadPreferences() async {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }

        do {
            let token = try KeychainManager.shared.getJWT()
            let jwt = token
            guard let userId = jwt.getUserIdFromJWT() else {
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    self?.errorMessage = "Jeton invalide — impossible de récupérer l'ID utilisateur."
                }
                return
            }

            PreferencesService.shared.fetchPreferences(userId: userId, token: jwt)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    // Fin du chargement
                    self?.isLoading = false

                    if case let .failure(error) = completion {
                        self?.errorMessage = error.localizedDescription
                        #if DEBUG
                        print("⚠️ Fetch preferences error: \(error)")
                        #endif
                    }
                } receiveValue: { [weak self] prefs in
                    self?.preferences = prefs
                }
                .store(in: &cancellables)

        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                self?.errorMessage = "Impossible de récupérer le token : \(error.localizedDescription)"
            }
        }
    }

    func savePreferences() async {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }

        do {
            let token = try KeychainManager.shared.getJWT()
            let jwt = token
            guard let userId = jwt.getUserIdFromJWT() else {
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    self?.errorMessage = "Jeton invalide — impossible de récupérer l'ID utilisateur."
                }
                return
            }

            PreferencesService.shared.savePreferences(userId: userId, preferences: preferences, token: jwt)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    // Fin du chargement
                    self?.isLoading = false

                    if case let .failure(error) = completion {
                        self?.errorMessage = error.localizedDescription
                        #if DEBUG
                        print("⚠️ Save preferences error: \(error)")
                        #endif
                    }
                } receiveValue: { [weak self] returnedPrefs in
                    // On peut mettre à jour localement l'objet avec la version renvoyée par le serveur
                    self?.preferences = returnedPrefs
                    self?.navigateToHome = true  // Trigger navigation
                }
                .store(in: &cancellables)

        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                self?.errorMessage = "Impossible de récupérer le token : \(error.localizedDescription)"
            }
        }
    }
}
