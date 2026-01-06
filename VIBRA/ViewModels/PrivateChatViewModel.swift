//
//  PrivateChatViewModel.swift
//  VIBRA
//
//  ViewModel for the private chat screen
//

import Foundation
import Combine
import UIKit

final class PrivateChatViewModel: ObservableObject {
    @Published var messages: [DirectMessage] = []
    @Published var isLoading = false
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var conversation: Conversation?
    @Published var hasMoreMessages = false
    
    private let conversationId: String?
    private let recipientId: String?
    private let socketManager = ConversationSocketManager.shared
    private let conversationService = ConversationService.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String?
    
    // For initiating new conversation
    init(recipientId: String) {
        self.recipientId = recipientId
        self.conversationId = nil
        
        // Get current user ID immediately before setup
        if let token = try? KeychainManager.shared.getJWT(),
           let userId = JWTHelper.extractUserId(from: token) {
            self.currentUserId = userId
            print("🔑 Current user ID set: \(userId)")
        } else {
            print("❌ Failed to get current user ID from token")
        }
        
        setupBindings()
        initiateConversation()
    }
    
    // For existing conversation (from list)
    init(conversationId: String, conversation: Conversation? = nil) {
        self.conversationId = conversationId
        self.recipientId = nil
        self.conversation = conversation
        
        // Get current user ID immediately
        if let token = try? KeychainManager.shared.getJWT(),
           let userId = JWTHelper.extractUserId(from: token) {
            self.currentUserId = userId
            print("🔑 Current user ID set: \(userId)")
        }
        
        setupBindings()
        loadConversation()
    }
    
    private func setupBindings() {
        socketManager.conversationReadySubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] conversation, messages, room in
                guard let self = self else { return }
                self.conversation = conversation
                self.messages = messages.sorted { $0.createdAt < $1.createdAt }
                self.isLoading = false
            }
            .store(in: &cancellables)
        
        socketManager.newMessageSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message, convId in
                guard let self = self else { return }
                if let currentConvId = self.conversation?.conversationId,
                   currentConvId == convId {
                    if !self.messages.contains(where: { $0.id == message.id }) {
                        self.messages.append(message)
                        self.messages.sort { $0.createdAt < $1.createdAt }
                    }
                    self.isSending = false
                }
            }
            .store(in: &cancellables)
        
        socketManager.messagesListSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] convId, messages, hasMore in
                guard let self = self else { return }
                if let currentConvId = self.conversationId, currentConvId == convId {
                    self.messages = messages.sorted { $0.createdAt < $1.createdAt }
                    self.hasMoreMessages = hasMore
                    self.isLoading = false
                }
            }
            .store(in: &cancellables)
        
        socketManager.errorSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self = self else { return }
                
                // Parse backend errors for better user messages
                if error.contains("E11000") && error.contains("duplicate key") {
                    print("⚠️ Backend error: Attempting to create conversation with same user twice")
                    print("⚠️ This is a backend bug - check backend logs")
                    self.errorMessage = "Unable to create conversation. Please try again."
                } else {
                    self.errorMessage = error
                }
                
                self.isLoading = false
                self.isSending = false
            }
            .store(in: &cancellables)
    }
    
    private func initiateConversation() {
        guard let recipientId = recipientId else {
            print("❌ No recipientId provided")
            errorMessage = "Invalid recipient"
            isLoading = false
            return
        }
        
        print("🎯 Initiating conversation:")
        print("🎯 Current User ID: \(currentUserId ?? "nil")")
        print("🎯 Recipient ID: \(recipientId)")
        
        // Prevent user from creating conversation with themselves
        if recipientId == currentUserId {
            print("⚠️ Attempting to message self - blocked")
            errorMessage = "You cannot send messages to yourself"
            isLoading = false
            return
        }
        
        isLoading = true
        socketManager.initiateConversation(recipientId: recipientId)
        print("📤 Sent initiateConversation with recipientId: \(recipientId)")
    }
    
    private func loadConversation() {
        guard let conversationId = conversationId else { return }
        isLoading = true
        socketManager.joinConversation(conversationId: conversationId)
        socketManager.getMessages(conversationId: conversationId, limit: 50)
    }
    
    func sendTextMessage(_ text: String) {
        guard let conversationId = conversation?.conversationId,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        isSending = true
        socketManager.sendTextMessage(conversationId: conversationId, content: text)
    }
    
    func sendImageMessage(_ image: UIImage) {
        guard let conversationId = conversation?.conversationId else {
            errorMessage = "No conversation available"
            return
        }
        isSending = true
        conversationService.uploadImage(image) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let imageUrl):
                    self?.socketManager.sendImageMessage(conversationId: conversationId, imageUrl: imageUrl)
                case .failure(let error):
                    self?.errorMessage = "Failed to upload image: \(error.localizedDescription)"
                    self?.isSending = false
                }
            }
        }
    }
    
    func sendAudioMessage(fileURL: URL, duration: Int) {
        guard let conversationId = conversation?.conversationId else {
            errorMessage = "No conversation available"
            return
        }
        isSending = true
        conversationService.uploadAudio(fileURL: fileURL) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let audioUrl):
                    self?.socketManager.sendAudioMessage(conversationId: conversationId, audioUrl: audioUrl, duration: duration)
                case .failure(let error):
                    self?.errorMessage = "Failed to upload audio: \(error.localizedDescription)"
                    self?.isSending = false
                }
            }
        }
    }
    
    func loadMoreMessages() {
        guard let conversationId = conversationId,
              !isLoading,
              hasMoreMessages,
              let oldestMessage = messages.first else {
            return
        }
        isLoading = true
        socketManager.getMessages(conversationId: conversationId, limit: 50, before: oldestMessage.id)
    }
    
    func isMessageFromCurrentUser(_ message: DirectMessage) -> Bool {
        guard let currentUserId = currentUserId else { return false }
        return message.senderId.id == currentUserId
    }
}
