//
//  ChatsViewModel.swift
//  VIBRA
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ChatsViewModel: ObservableObject {

    enum Mode {
        case list
        case chat(sortieId: String, sortieTitle: String?)
    }

    let mode: Mode

    // MARK: - LISTE

    @Published var userId: String?
    @Published var isLoadingList: Bool = false
    @Published var listErrorMessage: String?
    @Published var participations: [Participation] = []

    var acceptedChats: [Participation] {
        participations.filter { $0.status == "ACCEPTEE" && $0.sortie?.id != nil }
    }

    // MARK: - CHAT

    private(set) var chatSortieId: String?
    private(set) var chatSortieTitle: String?

    @Published var messages: [ChatMessage] = []
    @Published var isLoadingChat: Bool = false
    @Published var isSending: Bool = false
    @Published var chatErrorMessage: String?
    
    @Published var isWebSocketConnected: Bool = false
    @Published var isSomeoneTyping: Bool = false

    private var currentUserId: String?
    private var socketManager: SocketIOManager?

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
            Task { await loadChatMessages() }      // HTTP initial
            setupSocket(forSortieId: sortieId)     // temps réel
        }
    }
    
    deinit {
        socketManager?.disconnect()
    }

    var navigationTitle: String {
        switch mode {
        case .list: return "Mes chats"
        case .chat: return chatSortieTitle ?? "Chat"
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
            appendIncomingMessage(sent)
            // En parallèle, ton backend va aussi émettre receiveMessage
            // → appendIncomingMessage() évite les doublons grâce à l'id
        } catch {
            self.chatErrorMessage = "Échec de l'envoi: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Socket.IO
    
    private func setupSocket(forSortieId sortieId: String) {
        guard let baseURL = ChatService.shared.baseURLAsURL else {
            print("❌ ChatsViewModel: baseURL invalide")
            return
        }
        
        let manager = SocketIOManager(
            baseURL: baseURL,
            tokenProvider: { try KeychainManager.shared.getJWT() }
        )
        self.socketManager = manager
        
        manager.onEvent = { [weak self] event in
            guard let self = self else { return }
            print("🎯 [ChatsViewModel] event:", event)
            
            switch event {
            case .connected:
                self.isWebSocketConnected = true
            case .disconnected:
                self.isWebSocketConnected = false
            case .reconnecting:
                self.isWebSocketConnected = false
            case .joinedRoom(let sId, let msgs):
                guard sId == self.chatSortieId else { return }
                // On remplace par les 50 derniers messages renvoyés par le WS
                self.messages = msgs.sorted { ($0.createdDate ?? .distantPast) < ($1.createdDate ?? .distantPast) }
            case .newMessage(let msg, let sId):
                guard sId == self.chatSortieId else { return }
                self.appendIncomingMessage(msg)
            case .typing(_, let sId, let isTyping):
                guard sId == self.chatSortieId else { return }
                self.isSomeoneTyping = isTyping
            case .messageRead:
                break
            case .onlineUsers:
                break
            case .error(let message):
                self.chatErrorMessage = message
            }
        }
        
        manager.start(sortieId: sortieId)
    }
    
    private func appendIncomingMessage(_ message: ChatMessage) {
        if messages.contains(where: { $0.id == message.id }) {
            return
        }
        messages.append(message)
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
