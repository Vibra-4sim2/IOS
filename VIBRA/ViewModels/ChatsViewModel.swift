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
    @Published var isUploadingMedia: Bool = false
    
    // MARK: - POLL
    @Published var isPresentingPollSheet: Bool = false
    @Published var pollQuestion: String = ""
    @Published var pollOptions: [String] = ["", ""]
    @Published var pollAllowMultiple: Bool = false
    @Published var pollClosesAt: Date? = nil
    
    // Audio recorder & player
    var audioRecorder = AudioRecorderManager()
    var audioPlayer = AudioPlayerManager()
    
    private var cancellables = Set<AnyCancellable>()

    private var currentUserId: String?
    private var socketManager: SocketIOManager?

    init(mode: Mode) {
        self.mode = mode
        
        // Observer les changements du recorder et player pour forcer la mise à jour de la vue
        audioRecorder.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        
        audioPlayer.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)

        switch mode {
        case .list:
            Task { await loadList() }
        case .chat(let sortieId, let sortieTitle):
            self.chatSortieId = sortieId
            self.chatSortieTitle = sortieTitle
            loadCurrentUserId()
            Task { await loadChatMessages() }
            setupSocket(forSortieId: sortieId)
        }
    }

    var navigationTitle: String {
        switch mode {
        case .list: return "Mes chats"
        case .chat: return chatSortieTitle ?? "Chat"
        }
    }

    func isFromCurrentUser(_ message: ChatMessage) -> Bool {
        guard let uid = currentUserId else { return false }
        if let sender = message.sender, sender.id == uid { return true }
        if let sid = message.senderId, sid == uid { return true }
        return false
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
            var sortedMessages = loaded.sorted { ($0.createdDate ?? .distantPast) < ($1.createdDate ?? .distantPast) }
            
            // Check if there are any poll messages without poll data
            let hasPollMessagesWithoutData = sortedMessages.contains { $0.type == .poll && $0.poll == nil }
            
            if hasPollMessagesWithoutData {
                print("🔍 [ChatsViewModel] Found poll messages without data, fetching polls...")
                
                // Get the chatId from the first message (they all have the same chatId)
                if let chatId = sortedMessages.first?.chatId {
                    do {
                        // Fetch all polls for this chat
                        let pollsResponse = try await PollService.shared.getChatPolls(chatId: chatId, page: 1, limit: 100)
                        let polls = pollsResponse.polls
                        print("✅ [ChatsViewModel] Fetched \(polls.count) polls for chat")
                        
                        // Match polls to messages
                        for (index, message) in sortedMessages.enumerated() {
                            if message.type == .poll && message.poll == nil {
                                print("🔍 [ChatsViewModel] Trying to match message at index \(index), content=\(message.content ?? "nil")")
                                
                                // Try to find matching poll by question in content field
                                if let question = message.content,
                                   let matchingPoll = polls.first(where: { $0.question == question }) {
                                    let updatedMessage = message.withUpdatedPoll(matchingPoll)
                                    sortedMessages[index] = updatedMessage
                                    print("✅ [ChatsViewModel] Matched poll '\(question)' to message by question")
                                } else if let messageDate = message.createdDate,
                                          let matchingPoll = polls.first(where: { poll in
                                    guard let pollDate = poll.createdDate else { return false }
                                    return abs(pollDate.timeIntervalSince1970 - messageDate.timeIntervalSince1970) < 5.0
                                }) {
                                    // Fallback 1: try to match by creation time (within 5 seconds - increased tolerance)
                                    let updatedMessage = message.withUpdatedPoll(matchingPoll)
                                    sortedMessages[index] = updatedMessage
                                    print("✅ [ChatsViewModel] Matched poll by timestamp to message (time diff < 5s)")
                                } else if let content = message.content, !content.isEmpty, content.count == 24 {
                                    // Fallback 2: content might be a MongoDB ObjectId (24 hex chars)
                                    if let matchingPoll = polls.first(where: { $0.id == content }) {
                                        let updatedMessage = message.withUpdatedPoll(matchingPoll)
                                        sortedMessages[index] = updatedMessage
                                        print("✅ [ChatsViewModel] Matched poll by ID in content field")
                                    } else {
                                        print("❌ [ChatsViewModel] Content looks like an ID but no matching poll found: \(content)")
                                    }
                                } else {
                                    print("❌ [ChatsViewModel] Could not match poll for message with content=\(message.content ?? "nil"), trying last resort...")
                                    
                                    // Last resort: match by order if we have unmatchedpolls
                                    let unmatchedPolls = polls.filter { poll in
                                        !sortedMessages.contains(where: { $0.poll?.id == poll.id })
                                    }
                                    if let firstUnmatchedPoll = unmatchedPolls.first {
                                        let updatedMessage = message.withUpdatedPoll(firstUnmatchedPoll)
                                        sortedMessages[index] = updatedMessage
                                        print("⚠️ [ChatsViewModel] Matched poll by order (last resort): \(firstUnmatchedPoll.question)")
                                    }
                                }
                            }
                        }
                    } catch {
                        print("❌ [ChatsViewModel] Failed to fetch chat polls: \(error)")
                    }
                }
            }
            
            self.messages = sortedMessages
        } catch {
            self.chatErrorMessage = "Erreur de chargement du chat: \(error.localizedDescription)"
            self.messages = []
        }
        isLoadingChat = false
    }

    // MARK: - Envoi message texte
    
    func sendText(_ text: String) {
        guard case .chat = mode, let sortieId = chatSortieId else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }

        Task { await sendTextAsync(trimmed, sortieId: sortieId) }
    }

    private func sendTextAsync(_ text: String, sortieId: String) async {
        guard let socketManager = socketManager else {
            self.chatErrorMessage = "Connexion temps réel non initialisée"
            return
        }

        isSending = true
        defer { isSending = false }

        socketManager.send(text: text)
    }

    // MARK: - Envoi image
    
    func sendImage(data: Data, fileName: String = "image.jpg", mimeType: String = "image/jpeg") {
        guard case .chat = mode, let sortieId = chatSortieId else { return }
        guard !isUploadingMedia else { return }

        Task { await sendImageAsync(data: data, fileName: fileName, mimeType: mimeType, sortieId: sortieId) }
    }

    private func sendImageAsync(data: Data, fileName: String, mimeType: String, sortieId: String) async {
        guard let socketManager = socketManager else {
            self.chatErrorMessage = "Connexion temps réel non initialisée"
            return
        }

        isUploadingMedia = true
        defer { isUploadingMedia = false }

        do {
            let uploadResponse = try await ChatService.shared.uploadMedia(
                fileData: data,
                fileName: fileName,
                mimeType: mimeType
            )

            socketManager.sendMedia(
                type: .image,
                mediaUrl: uploadResponse.url,
                thumbnailUrl: nil,
                mediaDuration: uploadResponse.duration,
                fileSize: uploadResponse.size,
                fileName: uploadResponse.originalName,
                mimeType: uploadResponse.mimeType,
                sortieId: sortieId
            )

        } catch {
            self.chatErrorMessage = "Erreur lors de l'envoi de l'image: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Envoi audio (message vocal)
    
    func startRecordingAudio() {
        print("🎤 [ChatsViewModel] startRecordingAudio called")
        print("🎤 [ChatsViewModel] hasPermission:", audioRecorder.hasPermission)
        print("🎤 [ChatsViewModel] isRecording BEFORE:", audioRecorder.isRecording)
        
        // IMPORTANT: Vérifier AVANT d'essayer d'enregistrer
        guard !audioRecorder.isRecording else {
            print("⚠️ [ChatsViewModel] Already recording, ignoring")
            return
        }
        
        do {
            _ = try audioRecorder.startRecording()
            print("✅ [ChatsViewModel] Recording started successfully")
            print("🎤 [ChatsViewModel] isRecording AFTER:", audioRecorder.isRecording)
        } catch {
            print("❌ [ChatsViewModel] Recording error:", error)
            self.chatErrorMessage = "Erreur d'enregistrement: \(error.localizedDescription)"
        }
    }
    
    func cancelRecordingAudio() {
        audioRecorder.cancelRecording()
    }
    
    func sendRecordedAudio() {
        guard case .chat = mode, let sortieId = chatSortieId else { return }
        guard let result = audioRecorder.stopRecording() else { return }
        
        let fileURL = result.url
        let duration = result.duration
        
        // Validation
        do {
            try audioRecorder.validateRecording(url: fileURL, duration: duration)
        } catch {
            self.chatErrorMessage = error.localizedDescription
            return
        }
        
        Task {
            await sendAudioAsync(fileURL: fileURL, duration: duration, sortieId: sortieId)
        }
    }
    
    private func sendAudioAsync(fileURL: URL, duration: TimeInterval, sortieId: String) async {
        guard let socketManager = socketManager else {
            self.chatErrorMessage = "Connexion temps réel non initialisée"
            return
        }
        
        isUploadingMedia = true
        defer { isUploadingMedia = false }
        
        do {
            // Lecture du fichier
            let audioData = try Data(contentsOf: fileURL)
            let fileName = fileURL.lastPathComponent
            let mimeType = "audio/mp4" // Format M4A/AAC
            
            // Upload vers backend
            let uploadResponse = try await ChatService.shared.uploadMedia(
                fileData: audioData,
                fileName: fileName,
                mimeType: mimeType
            )
            
            // Envoi du message audio via Socket.IO
            socketManager.sendMedia(
                type: .audio,
                mediaUrl: uploadResponse.url,
                thumbnailUrl: nil,
                mediaDuration: duration,
                fileSize: uploadResponse.size,
                fileName: uploadResponse.originalName,
                mimeType: uploadResponse.mimeType,
                sortieId: sortieId
            )
            
            // Nettoyage du fichier temporaire
            try? FileManager.default.removeItem(at: fileURL)
            
        } catch {
            self.chatErrorMessage = "Erreur lors de l'envoi du message vocal: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Lecture audio
    
    func playAudio(url: URL, messageId: String) {
        Task {
            do {
                try await audioPlayer.play(url: url, messageId: messageId)
            } catch {
                self.chatErrorMessage = "Erreur de lecture: \(error.localizedDescription)"
            }
        }
    }
    
    func pauseAudio() {
        audioPlayer.pause()
    }
    
    func stopAudio() {
        audioPlayer.stop()
    }
    
    func seekAudio(to time: TimeInterval) {
        audioPlayer.seek(to: time)
    }
    
    // MARK: - Poll
    
    func openPollSheet() {
        isPresentingPollSheet = true
    }
    
    func resetPollDraft() {
        pollQuestion = ""
        pollOptions = ["", ""]
        pollAllowMultiple = false
        pollClosesAt = nil
    }
    
    func addPollOptionField() {
        pollOptions.append("")
    }
    
    func removePollOptionField(at index: Int) {
        guard pollOptions.count > 2, index < pollOptions.count else { return }
        pollOptions.remove(at: index)
    }
    
    func createPoll() {
        guard case .chat = mode, let sortieId = chatSortieId else { return }
        guard !pollQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            chatErrorMessage = "La question du sondage ne peut pas être vide"
            return
        }
        
        let validOptions = pollOptions.compactMap { opt in
            let trimmed = opt.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        
        guard validOptions.count >= 2 else {
            chatErrorMessage = "Un sondage doit avoir au moins 2 options"
            return
        }
        
        guard let socketManager = socketManager else {
            chatErrorMessage = "Connexion temps réel non initialisée"
            return
        }
        
        let payload = CreatePollPayload(
            question: pollQuestion,
            options: validOptions,
            allowMultiple: pollAllowMultiple,
            closesAt: pollClosesAt
        )
        
        socketManager.sendCreatePoll(sortieId: sortieId, poll: payload)
        isPresentingPollSheet = false
        resetPollDraft()
    }
    
    func vote(on message: ChatMessage, optionIds: [String]) {
        guard !optionIds.isEmpty else { return }
        guard let poll = message.poll else { return }
        guard !poll.isClosed else {
            chatErrorMessage = "Ce sondage est terminé."
            return
        }
        guard let socketManager = socketManager else {
            chatErrorMessage = "Connexion temps réel non initialisée"
            return
        }
        socketManager.sendVotePoll(pollId: poll.id, optionIds: optionIds)
    }
    
    func closePoll(message: ChatMessage) {
        guard let poll = message.poll else { return }
        guard let currentUserId = currentUserId, poll.creatorId == currentUserId else {
            chatErrorMessage = "Seul le créateur du sondage peut le fermer."
            return
        }
        guard let socketManager = socketManager else {
            chatErrorMessage = "Connexion temps réel non initialisée"
            return
        }
        socketManager.sendClosePoll(pollId: poll.id)
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
                print("🔥 [ChatsViewModel] joinedRoom received with \(msgs.count) messages")
                
                // Sort messages by creation date
                var sortedMsgs = msgs.sorted { ($0.createdDate ?? .distantPast) < ($1.createdDate ?? .distantPast) }
                
                // Check if there are poll messages without poll data
                let hasPollMessagesWithoutData = sortedMsgs.contains { $0.type == .poll && $0.poll == nil }
                
                if hasPollMessagesWithoutData {
                    print("🔍 [ChatsViewModel] joinedRoom has poll messages without data, fetching polls...")
                    
                    // Get the chatId from the first message
                    if let chatId = sortedMsgs.first?.chatId {
                        Task {
                            do {
                                // Fetch all polls for this chat
                                let pollsResponse = try await PollService.shared.getChatPolls(chatId: chatId, page: 1, limit: 100)
                                let polls = pollsResponse.polls
                                print("✅ [ChatsViewModel] Fetched \(polls.count) polls for joinedRoom")
                                
                                // Match polls to messages using the same logic as loadChatMessages
                                for (index, message) in sortedMsgs.enumerated() {
                                    if message.type == .poll && message.poll == nil {
                                        // Try matching by question
                                        if let question = message.content,
                                           let matchingPoll = polls.first(where: { $0.question == question }) {
                                            sortedMsgs[index] = message.withUpdatedPoll(matchingPoll)
                                            print("✅ [ChatsViewModel] Matched poll '\(question)' in joinedRoom by question")
                                        } else if let messageDate = message.createdDate,
                                                  let matchingPoll = polls.first(where: { poll in
                                            guard let pollDate = poll.createdDate else { return false }
                                            return abs(pollDate.timeIntervalSince1970 - messageDate.timeIntervalSince1970) < 5.0
                                        }) {
                                            sortedMsgs[index] = message.withUpdatedPoll(matchingPoll)
                                            print("✅ [ChatsViewModel] Matched poll in joinedRoom by timestamp")
                                        } else if let content = message.content, !content.isEmpty, content.count == 24,
                                                  let matchingPoll = polls.first(where: { $0.id == content }) {
                                            sortedMsgs[index] = message.withUpdatedPoll(matchingPoll)
                                            print("✅ [ChatsViewModel] Matched poll in joinedRoom by ID")
                                        } else {
                                            // Last resort: match by order
                                            let unmatchedPolls = polls.filter { poll in
                                                !sortedMsgs.contains(where: { $0.poll?.id == poll.id })
                                            }
                                            if let firstUnmatchedPoll = unmatchedPolls.first {
                                                sortedMsgs[index] = message.withUpdatedPoll(firstUnmatchedPoll)
                                                print("⚠️ [ChatsViewModel] Matched poll in joinedRoom by order: \(firstUnmatchedPoll.question)")
                                            }
                                        }
                                    }
                                }
                                
                                // Update messages on main thread
                                await MainActor.run {
                                    self.messages = sortedMsgs
                                    print("✅ [ChatsViewModel] Updated messages from joinedRoom with polls")
                                }
                            } catch {
                                print("❌ [ChatsViewModel] Failed to fetch polls for joinedRoom: \(error)")
                                await MainActor.run {
                                    self.messages = sortedMsgs
                                }
                            }
                        }
                    } else {
                        self.messages = sortedMsgs
                    }
                } else {
                    self.messages = sortedMsgs
                    print("✅ [ChatsViewModel] joinedRoom messages set (no poll fetching needed)")
                }
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
            case .pollCreated(let poll, _):
                print("📩 pollCreated received:", poll.id)
                let pollMessage = ChatMessage.createPollMessage(from: poll, sender: nil)
                self.appendIncomingMessage(pollMessage)
                
            case .pollVoted(let poll, _, _, _):
                print("📩 pollVoted received:", poll.id)
                if let index = self.messages.firstIndex(where: { $0.poll?.id == poll.id }) {
                    let updatedMessage = self.messages[index].withUpdatedPoll(poll)
                    self.messages[index] = updatedMessage
                    print("✅ Poll updated in message at index \(index)")
                } else {
                    let pollMessage = ChatMessage.createPollMessage(from: poll, sender: nil)
                    self.appendIncomingMessage(pollMessage)
                }
                
            case .pollClosed(let poll, _):
                print("📩 pollClosed received:", poll.id)
                if let index = self.messages.firstIndex(where: { $0.poll?.id == poll.id }) {
                    let updatedMessage = self.messages[index].withUpdatedPoll(poll)
                    self.messages[index] = updatedMessage
                    print("✅ Poll closed and updated in message at index \(index)")
                }
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
