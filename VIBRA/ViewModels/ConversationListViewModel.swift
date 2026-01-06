//
//  ConversationListViewModel.swift
//  VIBRA
//
//  ViewModel for the conversations list screen
//

import Foundation
import Combine

final class ConversationListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isConnected = false
    
    private let socketManager = ConversationSocketManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        connectIfNeeded()
    }
    
    deinit {
        // Don't disconnect here, let the app manage the connection lifecycle
    }
    
    private func setupBindings() {
        // Subscribe to socket connection status
        socketManager.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$isConnected)
        
        // Subscribe to conversations list updates
        socketManager.conversationsListSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] conversations in
                self?.conversations = conversations.sorted { $0.updatedAt > $1.updatedAt }
                self?.isLoading = false
            }
            .store(in: &cancellables)
        
        // Subscribe to new messages (to update conversation list)
        socketManager.newMessageSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in
                // Conversation list will be updated automatically by socket
            }
            .store(in: &cancellables)
        
        // Subscribe to conversation deletion
        socketManager.conversationDeletedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] conversationId in
                self?.conversations.removeAll { $0.conversationId == conversationId }
            }
            .store(in: &cancellables)
        
        // Subscribe to errors
        socketManager.errorSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.errorMessage = error
                self?.isLoading = false
            }
            .store(in: &cancellables)
        
        // Also subscribe to the published conversations from socket manager
        socketManager.$conversations
            .receive(on: DispatchQueue.main)
            .assign(to: &$conversations)
    }
    
    func connectIfNeeded() {
        guard !socketManager.isConnected else {
            // Already connected, just request conversations
            refresh()
            return
        }
        
        // Get token and userId
        guard let token = try? KeychainManager.shared.getJWT(),
              let userId = JWTHelper.extractUserId(from: token) else {
            errorMessage = "Not authenticated"
            return
        }
        
        isLoading = true
        socketManager.connect(token: token, userId: userId)
    }
    
    func refresh() {
        isLoading = true
        errorMessage = nil
        socketManager.getMyConversations()
    }
    
    func deleteConversation(_ conversation: Conversation) {
        socketManager.deleteConversation(conversationId: conversation.conversationId)
    }
    
    /// Find existing conversation with a specific user
    /// Returns the conversation if found, nil otherwise
    func findConversation(withUserId userId: String) -> Conversation? {
        return conversations.first { conversation in
            conversation.otherUser.id == userId
        }
    }
}
