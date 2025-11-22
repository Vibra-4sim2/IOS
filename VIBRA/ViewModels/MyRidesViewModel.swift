//
//  MyRidesViewModel.swift
//  VIBRA
//
//  Created by mac book pro on 11/22/25.
//
import Foundation
import Combine

@MainActor
final class MyRidesViewModel: ObservableObject {
    @Published var allItems: [RideWithCreator] = []
    @Published var myItems: [RideWithCreator] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUserId: String?

    @Published var searchText: String = "" {
        didSet {
            applyMyRidesFilter()
        }
    }

    init() {
        Task {
            await load()
        }
    }

    /// Charge les sorties + récupère l'ID utilisateur connecté depuis le JWT et applique le filtre "mes sorties".
    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            // 1) Récupérer l'utilisateur courant via le JWT
            try await loadCurrentUserIdFromJWT()

            // 2) Récupérer toutes les sorties avec créateur
            let fetched = try await HomeService.shared.fetchRidesWithCreators()
            self.allItems = fetched

            // 3) Appliquer le filtre "mes sorties"
            applyMyRidesFilter()
        } catch {
            self.errorMessage = "Erreur de chargement: \(error.localizedDescription)"
            self.allItems = []
            self.myItems = []
        }

        isLoading = false
    }

    /// Essaie d'extraire l'ID utilisateur depuis le JWT stocké dans le Keychain
    private func loadCurrentUserIdFromJWT() async throws {
        do {
            let token = try KeychainManager.shared.getJWT()
            if let userId = decodeUserId(fromJWT: token) {
                self.currentUserId = userId
            } else {
                self.currentUserId = nil
            }
        } catch {
            // Pas de token ou erreur Keychain => utilisateur non connecté
            self.currentUserId = nil
        }
    }

    /// Décodage minimal d'un JWT pour en extraire un champ "id" / "userId" / "sub"
    /// ⚠️ Adapte ici la clé selon ton backend.
    private func decodeUserId(fromJWT token: String) -> String? {
        // Format JWT: header.payload.signature
        let segments = token.split(separator: ".")
        guard segments.count >= 2 else { return nil }

        let payloadSegment = segments[1]

        // Base64URL -> Base64
        var base64 = String(payloadSegment)
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Ajouter le padding si nécessaire
        while base64.count % 4 != 0 {
            base64.append("=")
        }

        guard let payloadData = Data(base64Encoded: base64) else { return nil }

        guard let json = try? JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] else {
            return nil
        }

        // ➜ ADAPTER ICI suivant ton backend
        if let id = json["id"] as? String {
            return id
        }
        if let userId = json["userId"] as? String {
            return userId
        }
        if let sub = json["sub"] as? String {
            return sub
        }

        return nil
    }

    /// Applique le filtre "mes sorties" sur allItems en fonction de currentUserId + searchText
    func applyMyRidesFilter() {
        guard let currentUserId = currentUserId else {
            myItems = []
            return
        }

        var result = allItems.filter { item in
            if let creatorId = item.ride.createurId {
                return creatorId == currentUserId
            }
            return false
        }

        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            let lower = text.lowercased()
            result = result.filter { item in
                let title = item.ride.titre.lowercased()
                let desc = item.ride.description?.lowercased() ?? ""
                let creatorName = "\(item.creator?.firstName ?? "") \(item.creator?.lastName ?? "")".lowercased()
                return title.contains(lower) || desc.contains(lower) || creatorName.contains(lower)
            }
        }

        self.myItems = result
    }
}
