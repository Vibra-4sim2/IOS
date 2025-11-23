//
//  ChatsViewModel.swift
//  VIBRA
//
//  Created by mac book pro on 11/23/25.
//
import Foundation
import Combine

@MainActor
final class ChatsViewModel: ObservableObject {
    @Published var userId: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var participations: [Participation] = []

    /// Participations ACCEPTÉE pour lesquelles on a une sortie
    var acceptedChats: [Participation] {
        participations.filter { $0.status == "ACCEPTEE" && $0.sortie?.id != nil }
    }

    init() {
        Task {
            await load()
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            try loadUserIdFromJWT()
            guard let uid = userId else {
                errorMessage = "Utilisateur non connecté"
                participations = []
                isLoading = false
                return
            }

            let list = try await ParticipationService.shared.listParticipationsForUser(userId: uid)
            self.participations = list
        } catch {
            self.errorMessage = "Erreur de chargement: \(error.localizedDescription)"
            self.participations = []
        }

        isLoading = false
    }

    // MARK: - JWT

    private func loadUserIdFromJWT() throws {
        do {
            let token = try KeychainManager.shared.getJWT()
            if let uid = decodeUserId(fromJWT: token) {
                self.userId = uid
            } else {
                self.userId = nil
            }
        } catch {
            self.userId = nil
        }
    }

    private func decodeUserId(fromJWT token: String) -> String? {
        let segments = token.split(separator: ".")
        guard segments.count >= 2 else { return nil }

        let payloadSegment = segments[1]

        var base64 = String(payloadSegment)
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        while base64.count % 4 != 0 {
            base64.append("=")
        }

        guard let payloadData = Data(base64Encoded: base64) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] else {
            return nil
        }

        if let id = json["id"] as? String { return id }
        if let userId = json["userId"] as? String { return userId }
        if let sub = json["sub"] as? String { return sub }
        if let mongoId = json["_id"] as? String { return mongoId }

        return nil
    }
}
