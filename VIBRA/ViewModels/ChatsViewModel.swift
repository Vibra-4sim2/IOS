//
//  ChatsViewModel.swift
//  VIBRA
//
//  Gère :
//  - la liste des chats (sorties où je suis ACCEPTÉE)
//  - le détail d'un chat (messages d'une sortie donnée)
//

import Foundation
import SwiftUI
import Combine
@MainActor
final class ChatsViewModel: ObservableObject {

    // MARK: - Mode

    enum Mode {
        case list
        case chat(sortieId: String, sortieTitle: String?)
    }

    let mode: Mode

    // MARK: - Liste des chats (mode .list)

    @Published var userId: String?
    @Published var isLoadingList: Bool = false
    @Published var listErrorMessage: String?
    @Published var participations: [Participation] = []

    /// Participations ACCEPTÉE pour lesquelles on a une sortie
    var acceptedChats: [Participation] {
        participations.filter { $0.status == "ACCEPTEE" && $0.sortie?.id != nil }
    }

    // MARK: - Détail d'un chat (mode .chat)

    private(set) var chatSortieId: String?
    private(set) var chatSortieTitle: String?

    @Published var messages: [ChatMessage] = []
    @Published var isLoadingChat: Bool = false
    @Published var isSending: Bool = false
    @Published var chatErrorMessage: String?

    private var currentUserId: String?

    // MARK: - Init

    init(mode: Mode) {
        self.mode = mode

        switch mode {
        case .list:
            Task { await loadList() }
        case .chat(let sortieId, let sortieTitle):
            self.chatSortieId = sortieId
            self.chatSortieTitle = sortieTitle
            loadCurrentUserId()
            Task { await loadChatMessages() }
        }
    }

    // MARK: - Public helpers

    var navigationTitle: String {
        switch mode {
        case .list:
            return "Mes chats"
        case .chat:
            return chatSortieTitle ?? "Chat"
        }
    }

    func isFromCurrentUser(_ message: ChatMessage) -> Bool {
        guard let uid = currentUserId else { return false }
        return message.senderId == uid
    }

    // MARK: - LISTE

    func reloadList() {
        guard case .list = mode else { return }
        Task { await loadList() }
    }

    private func loadList() async {
        isLoadingList = true
        listErrorMessage = nil

        do {
            try loadUserIdFromJWT()
            guard let uid = userId else {
                listErrorMessage = "Utilisateur non connecté"
                participations = []
                isLoadingList = false
                return
            }

            let list = try await ParticipationService.shared.listParticipationsForUser(userId: uid)
            self.participations = list
        } catch {
            self.listErrorMessage = "Erreur de chargement: \(error.localizedDescription)"
            self.participations = []
        }

        isLoadingList = false
    }

    // MARK: - CHAT

    func reloadChatMessages() {
        guard case .chat = mode else { return }
        Task { await loadChatMessages() }
    }

    func loadChatMessages() async {
        guard case .chat = mode, let sortieId = chatSortieId else { return }

        isLoadingChat = true
        chatErrorMessage = nil
        do {
            let loaded = try await ChatService.shared.fetchMessages(sortieId: sortieId)
            self.messages = loaded
        } catch {
            self.chatErrorMessage = "Erreur de chargement du chat: \(error.localizedDescription)"
            self.messages = []
        }
        isLoadingChat = false
    }

    func sendText(_ text: String) {
        guard case .chat = mode, let sortieId = chatSortieId else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }

        Task { await sendTextAsync(trimmed, sortieId: sortieId) }
    }

    private func sendTextAsync(_ text: String, sortieId: String) async {
        isSending = true
        defer { isSending = false }

        do {
            let sent = try await ChatService.shared.sendTextMessage(sortieId: sortieId, content: text)
            messages.append(sent)
        } catch {
            self.chatErrorMessage = "Échec de l'envoi: \(error.localizedDescription)"
        }
    }

    // MARK: - JWT helpers

    private func loadUserIdFromJWT() throws {
        do {
            let token = try KeychainManager.shared.getJWT()
            if let uid = decodeUserId(fromJWT: token) {
                self.userId = uid
                self.currentUserId = uid
            } else {
                self.userId = nil
                self.currentUserId = nil
            }
        } catch {
            self.userId = nil
            self.currentUserId = nil
        }
    }

    private func loadCurrentUserId() {
        do {
            let token = try KeychainManager.shared.getJWT()
            currentUserId = decodeUserId(fromJWT: token)
        } catch {
            currentUserId = nil
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
