//
//  SocketIOManager.swift
//  VIBRA
//
//  Gestionnaire Socket.IO pour le chat temps réel avec le backend NestJS (/chat)
//

import Foundation
import SocketIO

final class SocketIOManager {
    
    enum Event {
        case connected
        case disconnected(Error?)
        case reconnecting(Int)
        case joinedRoom(sortieId: String, messages: [ChatMessage])
        case newMessage(ChatMessage, sortieId: String)
        case typing(userId: String, sortieId: String, isTyping: Bool)
        case messageRead(messageId: String, userId: String, sortieId: String)
        case onlineUsers(sortieId: String, userIds: [String], count: Int)
        case error(String)
    }
    
    var onEvent: ((Event) -> Void)?
    
    private let baseURL: URL
    private let tokenProvider: () throws -> String
    
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    
    private var currentSortieId: String?
    
    init(baseURL: URL, tokenProvider: @escaping () throws -> String) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
    }
    
    deinit {
        disconnect()
    }
    
    // MARK: - Connexion
    
    func start(sortieId: String) {
        currentSortieId = sortieId
        
        let token: String
        do {
            token = try tokenProvider()
        } catch {
            print("❌ SocketIOManager: impossible de récupérer le JWT:", error)
            DispatchQueue.main.async {
                self.onEvent?(.error("Token manquant pour la connexion temps réel"))
            }
            return
        }
        
        let config: SocketIOClientConfiguration = [
            .log(true),
            .compress,
            .forceNew(true),
            .reconnects(true),
            .reconnectAttempts(-1),
            .reconnectWait(1),
            .extraHeaders(["Authorization": "Bearer \(token)"]),
            .connectParams(["token": token])
        ]
        
        print("🚀 [SocketIO] connect base:", baseURL.absoluteString)
        let manager = SocketManager(socketURL: baseURL, config: config)
        self.manager = manager
        
        let socket = manager.socket(forNamespace: "/chat")
        self.socket = socket
        
        setupBasicHandlers(socket: socket)
        setupChatHandlers(socket: socket)
        
        socket.connect()
    }
    
    func disconnect() {
        print("🛑 [SocketIO] disconnect")
        socket?.disconnect()
        socket = nil
        manager = nil
        currentSortieId = nil
    }
    
    // MARK: - Emission
    
    func send(text: String) {
        guard let sortieId = currentSortieId else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let payload: [String: Any] = [
            "sortieId": sortieId,
            "type": "text", // MessageType.TEXT = 'text' côté backend
            "content": trimmed
        ]
        print("📤 [SocketIO] sendMessage payload:", payload)
        socket?.emit("sendMessage", payload)
    }
    
    func joinCurrentRoom() {
        guard let sortieId = currentSortieId else { return }
        let payload: [String: Any] = ["sortieId": sortieId]
        print("📤 [SocketIO] joinRoom payload:", payload)
        socket?.emit("joinRoom", payload)
    }
    
    func leaveCurrentRoom() {
        guard let sortieId = currentSortieId else { return }
        let payload: [String: Any] = ["sortieId": sortieId]
        print("📤 [SocketIO] leaveRoom payload:", payload)
        socket?.emit("leaveRoom", payload)
    }
    
    func sendTyping(isTyping: Bool) {
        guard let sortieId = currentSortieId else { return }
        let payload: [String: Any] = ["sortieId": sortieId, "isTyping": isTyping]
        print("📤 [SocketIO] typing payload:", payload)
        socket?.emit("typing", payload)
    }
    
    func markAsRead(messageId: String) {
        guard let sortieId = currentSortieId else { return }
        let payload: [String: Any] = [
            "sortieId": sortieId,
            "messageId": messageId
        ]
        print("📤 [SocketIO] markAsRead payload:", payload)
        socket?.emit("markAsRead", payload)
    }
    
    // MARK: - Handlers de base
    
    private func setupBasicHandlers(socket: SocketIOClient) {
        socket.on(clientEvent: .connect) { [weak self] data, _ in
            guard let self = self else { return }
            print("✅ [SocketIO] .connect (nsp: \(socket.nsp)) data:", data)
            DispatchQueue.main.async {
                self.onEvent?(.connected)
            }
            self.joinCurrentRoom()
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] data, _ in
            guard let self = self else { return }
            let reason = data.first as? String ?? "unknown"
            print("🔴 [SocketIO] .disconnect:", reason)
            DispatchQueue.main.async {
                self.onEvent?(.disconnected(nil))
            }
        }
        
        socket.on(clientEvent: .reconnectAttempt) { [weak self] data, _ in
            guard let self = self else { return }
            let attempt = data.first as? Int ?? -1
            print("🔁 [SocketIO] .reconnectAttempt:", attempt)
            DispatchQueue.main.async {
                self.onEvent?(.reconnecting(attempt))
            }
        }
        
        socket.on(clientEvent: .error) { [weak self] data, _ in
            guard let self = self else { return }
            print("❌ [SocketIO] .error data:", data)
            let message = (data.first as? String) ?? "Socket.IO error"
            DispatchQueue.main.async {
                self.onEvent?(.error(message))
            }
        }
        
        socket.on("connected") { data, _ in
            print("✅ [SocketIO] event 'connected' data:", data)
        }
    }
    
    // MARK: - Handlers métier (chat)
    
    private func setupChatHandlers(socket: SocketIOClient) {
        socket.on("joinedRoom") { [weak self] data, _ in
            print("📥 [SocketIO] event 'joinedRoom' raw:", data)
            guard
                let self = self,
                let dict = data.first as? [String: Any],
                let sortieId = dict["sortieId"] as? String,
                let messagesArray = dict["messages"]
            else {
                print("⚠️ [SocketIO] 'joinedRoom' payload invalide")
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: messagesArray, options: [])
                let decoded = try JSONDecoder().decode([ChatMessage].self, from: jsonData)
                DispatchQueue.main.async {
                    self.onEvent?(.joinedRoom(sortieId: sortieId, messages: decoded))
                }
            } catch {
                print("❌ [SocketIO] Décodage joinedRoom.messages échoué:", error)
            }
        }
        
        socket.on("receiveMessage") { [weak self] data, _ in
            print("📥 [SocketIO] event 'receiveMessage' raw:", data)
            guard
                let self = self,
                let dict = data.first as? [String: Any],
                let sortieId = dict["sortieId"] as? String,
                let messageDict = dict["message"]
            else {
                print("⚠️ [SocketIO] 'receiveMessage' payload invalide")
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: messageDict, options: [])
                let msg = try JSONDecoder().decode(ChatMessage.self, from: jsonData)
                DispatchQueue.main.async {
                    self.onEvent?(.newMessage(msg, sortieId: sortieId))
                }
            } catch {
                print("❌ [SocketIO] Décodage receiveMessage.message échoué:", error)
            }
        }
        
        socket.on("userTyping") { [weak self] data, _ in
            print("📥 [SocketIO] event 'userTyping' raw:", data)
            guard
                let self = self,
                let dict = data.first as? [String: Any],
                let userId = dict["userId"] as? String,
                let sortieId = dict["sortieId"] as? String,
                let isTyping = dict["isTyping"] as? Bool
            else { return }
            
            DispatchQueue.main.async {
                self.onEvent?(.typing(userId: userId, sortieId: sortieId, isTyping: isTyping))
            }
        }
        
        socket.on("messageRead") { [weak self] data, _ in
            print("📥 [SocketIO] event 'messageRead' raw:", data)
            guard
                let self = self,
                let dict = data.first as? [String: Any],
                let messageId = dict["messageId"] as? String,
                let userId = dict["userId"] as? String,
                let sortieId = dict["sortieId"] as? String
            else { return }
            
            DispatchQueue.main.async {
                self.onEvent?(.messageRead(messageId: messageId, userId: userId, sortieId: sortieId))
            }
        }
        
        socket.on("onlineUsers") { [weak self] data, _ in
            print("📥 [SocketIO] event 'onlineUsers' raw:", data)
            guard
                let self = self,
                let dict = data.first as? [String: Any],
                let sortieId = dict["sortieId"] as? String,
                let userIds = dict["userIds"] as? [String],
                let count = dict["count"] as? Int
            else { return }
            
            DispatchQueue.main.async {
                self.onEvent?(.onlineUsers(sortieId: sortieId, userIds: userIds, count: count))
            }
        }
        
        socket.on("error") { [weak self] data, _ in
            print("📥 [SocketIO] event 'error' raw:", data)
            guard
                let self = self,
                let dict = data.first as? [String: Any],
                let message = dict["message"] as? String
            else { return }
            
            DispatchQueue.main.async {
                self.onEvent?(.error(message))
            }
        }
    }
}
