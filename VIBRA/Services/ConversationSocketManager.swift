//
//  ConversationSocketManager.swift
//  VIBRA
//
//  Socket.IO manager for private messaging (separate from group chat)
//

import Foundation
import SocketIO
import Combine

final class ConversationSocketManager: ObservableObject {
    static let shared = ConversationSocketManager()
    
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    
    @Published var isConnected = false
    @Published var conversations: [Conversation] = []
    
    private var currentUserId: String?
    
    // Event subjects for ViewModels to subscribe
    let conversationsListSubject = PassthroughSubject<[Conversation], Never>()
    let conversationReadySubject = PassthroughSubject<(Conversation, [DirectMessage], String), Never>()
    let newMessageSubject = PassthroughSubject<(DirectMessage, String), Never>()
    let messagesListSubject = PassthroughSubject<(String, [DirectMessage], Bool), Never>()
    let conversationDeletedSubject = PassthroughSubject<String, Never>()
    let errorSubject = PassthroughSubject<String, Never>()
    
    private init() {}
    
    deinit {
        disconnect()
    }
    
    // MARK: - Connection
    
    func connect(token: String, userId: String) {
        // If already connected, check if it's the same user
        if socket != nil {
            if currentUserId == userId {
                print("⚠️ ConversationSocket already connected for same user - reusing connection")
                return
            } else {
                print("🔄 Different user detected - disconnecting old connection")
                print("   Old user: \(currentUserId ?? "unknown")")
                print("   New user: \(userId)")
                disconnect()  // Disconnect old user's socket first
            }
        }
        
        currentUserId = userId
        
        guard let url = URL(string: Constants.baseURL) else {
            print("❌ Invalid base URL")
            return
        }
        
        // Configure socket with authentication
        let config: SocketIOClientConfiguration = [
            .log(true),
            .compress,
            .forceWebsockets(true),
            .connectParams(["token": token]),
            .path("/socket.io"),
            .reconnects(true),
            .reconnectWait(2),
            .reconnectAttempts(5),
            .extraHeaders(["Authorization": "Bearer \(token)"])
        ]
        
        manager = SocketManager(socketURL: url, config: config)
        socket = manager?.socket(forNamespace: "/conversations")
        setupListeners()
        socket?.connect()
        
        print("🔌 Connecting to /conversations namespace at \(url.absoluteString)")
        print("🔌 Token: \(token.prefix(20))...")
        print("🔌 User ID: \(userId)")
    }
    
    func disconnect() {
        socket?.disconnect()
        socket = nil
        manager = nil
        isConnected = false
        print("🔌 Disconnected from /conversations")
    }
    
    // MARK: - Event Listeners
    
    private func setupListeners() {
        socket?.on(clientEvent: .connect) { [weak self] data, ack in
            print("✅ Socket.IO connected to /conversations")
            DispatchQueue.main.async {
                self?.isConnected = true
            }
        }
        
        socket?.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("❌ Disconnected: \(data)")
            DispatchQueue.main.async {
                self?.isConnected = false
            }
        }
        
        socket?.on("connected") { [weak self] data, ack in
            print("✅ Backend confirmed connection")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self?.getMyConversations()
            }
        }
        
        socket?.on("conversationsList") { [weak self] data, ack in
            self?.handleConversationsList(data: data)
        }
        
        socket?.on("conversationReady") { [weak self] data, ack in
            self?.handleConversationReady(data: data)
        }
        
        socket?.on("receiveDirectMessage") { [weak self] data, ack in
            self?.handleReceiveDirectMessage(data: data)
        }
        
        socket?.on("messagesList") { [weak self] data, ack in
            self?.handleMessagesList(data: data)
        }
        
        socket?.on("conversationDeleted") { [weak self] data, ack in
            self?.handleConversationDeleted(data: data)
        }
        
        socket?.on("error") { [weak self] data, ack in
            if let dict = data[0] as? [String: Any],
               let message = dict["message"] as? String {
                print("⚠️ Error: \(message)")
                self?.errorSubject.send(message)
            }
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleConversationsList(data: [Any]) {
        guard let dict = data[0] as? [String: Any],
              let conversationsData = dict["conversations"] as? [[String: Any]] else {
            return
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: conversationsData)
            let conversations = try JSONDecoder().decode([Conversation].self, from: jsonData)
            
            DispatchQueue.main.async { [weak self] in
                self?.conversations = conversations.sorted { $0.updatedAt > $1.updatedAt }
                self?.conversationsListSubject.send(conversations)
            }
            
            print("📋 Loaded \(conversations.count) conversations")
        } catch {
            print("❌ Error parsing conversations: \(error)")
        }
    }
    
    private func handleConversationReady(data: [Any]) {
        guard let dict = data[0] as? [String: Any],
              let conversationData = dict["conversation"] as? [String: Any],
              let messagesData = dict["messages"] as? [[String: Any]],
              let room = dict["room"] as? String else {
            return
        }
        
        do {
            let convJsonData = try JSONSerialization.data(withJSONObject: conversationData)
            let conversation = try JSONDecoder().decode(Conversation.self, from: convJsonData)
            
            let msgJsonData = try JSONSerialization.data(withJSONObject: messagesData)
            let messages = try JSONDecoder().decode([DirectMessage].self, from: msgJsonData)
            
            DispatchQueue.main.async { [weak self] in
                self?.conversationReadySubject.send((conversation, messages, room))
            }
            
            print("✅ Conversation ready: \(conversation.conversationId)")
        } catch {
            print("❌ Error parsing conversationReady: \(error)")
        }
    }
    
    private func handleReceiveDirectMessage(data: [Any]) {
        guard let dict = data[0] as? [String: Any],
              let messageData = dict["message"] as? [String: Any],
              let conversationId = dict["conversationId"] as? String else {
            return
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: messageData)
            let message = try JSONDecoder().decode(DirectMessage.self, from: jsonData)
            
            DispatchQueue.main.async { [weak self] in
                self?.newMessageSubject.send((message, conversationId))
                self?.getMyConversations()
            }
            
            print("📨 New message received")
        } catch {
            print("❌ Error parsing message: \(error)")
        }
    }
    
    private func handleMessagesList(data: [Any]) {
        guard let dict = data[0] as? [String: Any],
              let conversationId = dict["conversationId"] as? String,
              let messagesData = dict["messages"] as? [[String: Any]],
              let hasMore = dict["hasMore"] as? Bool else {
            return
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: messagesData)
            let messages = try JSONDecoder().decode([DirectMessage].self, from: jsonData)
            
            DispatchQueue.main.async { [weak self] in
                self?.messagesListSubject.send((conversationId, messages, hasMore))
            }
            
            print("📜 Loaded \(messages.count) messages")
        } catch {
            print("❌ Error parsing messages: \(error)")
        }
    }
    
    private func handleConversationDeleted(data: [Any]) {
        guard let dict = data[0] as? [String: Any],
              let conversationId = dict["conversationId"] as? String else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.conversations.removeAll { $0.conversationId == conversationId }
            self?.conversationDeletedSubject.send(conversationId)
        }
    }
    
    // MARK: - Emit Events WITH RETRY LOGIC
    
    func getMyConversations() {
        guard socket?.status == .connected else {
            print("⚠️ Socket not connected")
            return
        }
        socket?.emit("getMyConversations")
    }
    
    func initiateConversation(recipientId: String) {
        func attemptEmit(retryCount: Int = 0) {
            guard let socket = socket else {
                errorSubject.send("Socket not initialized")
                return
            }
            
            print("🔍 Attempt \(retryCount + 1): Socket status = \(socket.status.rawValue), isConnected = \(isConnected)")
            
            if socket.status == .connected {
                print("✅ CONNECTED - Emitting initiateConversation")
                socket.emit("initiateConversation", ["recipientId": recipientId])
                print("📤 Sent: initiateConversation for \(recipientId)")
            } else if retryCount < 5 {
                print("⏳ Not connected, waiting... (attempt \(retryCount + 1)/5)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    attemptEmit(retryCount: retryCount + 1)
                }
            } else {
                print("❌ Failed after 5 attempts - Status: \(socket.status.rawValue)")
                errorSubject.send("Cannot connect to server")
            }
        }
        
        attemptEmit()
    }
    
    func joinConversation(conversationId: String) {
        func attemptEmit(retryCount: Int = 0) {
            guard let socket = socket else {
                errorSubject.send("Socket not initialized")
                return
            }
            
            if socket.status == .connected {
                socket.emit("joinConversation", ["conversationId": conversationId])
                print("📤 Joining conversation")
            } else if retryCount < 5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    attemptEmit(retryCount: retryCount + 1)
                }
            } else {
                errorSubject.send("Not connected")
            }
        }
        
        attemptEmit()
    }
    
    func sendTextMessage(conversationId: String, content: String) {
        guard socket?.status == .connected else {
            errorSubject.send("Not connected")
            return
        }
        
        socket?.emit("sendDirectMessage", [
            "conversationId": conversationId,
            "type": "text",
            "content": content
        ])
    }
    
    func sendImageMessage(conversationId: String, imageUrl: String) {
        guard socket?.status == .connected else {
            errorSubject.send("Not connected")
            return
        }
        
        socket?.emit("sendDirectMessage", [
            "conversationId": conversationId,
            "type": "image",
            "mediaUrl": imageUrl
        ])
    }
    
    func sendAudioMessage(conversationId: String, audioUrl: String, duration: Int) {
        guard socket?.status == .connected else {
            errorSubject.send("Not connected")
            return
        }
        
        socket?.emit("sendDirectMessage", [
            "conversationId": conversationId,
            "type": "audio",
            "mediaUrl": audioUrl,
            "duration": duration
        ])
    }
    
    func getMessages(conversationId: String, limit: Int = 50, before: String? = nil) {
        guard socket?.status == .connected else {
            return
        }
        
        var payload: [String: Any] = [
            "conversationId": conversationId,
            "limit": limit
        ]
        if let before = before {
            payload["before"] = before
        }
        
        socket?.emit("getMessages", payload)
    }
    
    func deleteConversation(conversationId: String) {
        guard socket?.status == .connected else {
            errorSubject.send("Not connected")
            return
        }
        
        socket?.emit("deleteConversation", ["conversationId": conversationId])
    }
}
