//
//  PrivateChatView.swift
//  VIBRA
//
//  Private 1-on-1 chat screen with text, image, and voice message support
//

import SwiftUI
import PhotosUI

struct PrivateChatView: View {
    let conversationId: String?
    let recipientId: String?
    
    @StateObject private var viewModel: PrivateChatViewModel
    @StateObject private var audioRecorder = AudioRecorderManager()
    @StateObject private var audioPlayer = AudioPlayerManager()
    
    @State private var messageText = ""
    @State private var isRecording = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingError = false
    @State private var scrollProxy: ScrollViewProxy?
    
    // For existing conversation (from list) - pass conversation object to avoid loading state
    init(conversationId: String, conversation: Conversation? = nil) {
        self.conversationId = conversationId
        self.recipientId = nil
        _viewModel = StateObject(wrappedValue: PrivateChatViewModel(conversationId: conversationId, conversation: conversation))
    }
    
    // For new conversation (from profile)
    init(recipientId: String) {
        self.conversationId = nil
        self.recipientId = recipientId
        _viewModel = StateObject(wrappedValue: PrivateChatViewModel(recipientId: recipientId))
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [AppColors.BackgroundGradientStart, AppColors.BackgroundGradientEnd]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if viewModel.isLoading && viewModel.messages.isEmpty {
                    loadingView
                } else {
                    messagesScrollView
                    inputBar
                }
            }
        }
        .navigationTitle(viewModel.conversation?.otherUser.displayName ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .onChange(of: viewModel.errorMessage) { error in
            showingError = error != nil
        }
        .onChange(of: selectedImage) { image in
            if let image = image {
                sendImage(image)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
    
    // MARK: - Messages Scroll View
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Load more button
                    if viewModel.hasMoreMessages {
                        Button {
                            viewModel.loadMoreMessages()
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(AppColors.GreenAccent)
                                }
                                Text("Load more")
                                    .font(.caption)
                                    .foregroundColor(AppColors.TextSecondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    // Messages
                    ForEach(viewModel.messages) { message in
                        MessageRowView(
                            message: message,
                            isFromCurrentUser: viewModel.isMessageFromCurrentUser(message),
                            audioPlayer: audioPlayer
                        )
                        .id(message.id)
                    }
                }
                .padding()
            }
            .onAppear {
                scrollProxy = proxy
                scrollToBottom()
            }
            .onChange(of: viewModel.messages.count) { _ in
                scrollToBottom()
            }
        }
    }
    
    // MARK: - Input Bar
    
    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(AppColors.BorderColor)
            
            HStack(spacing: 12) {
                // Image picker button
                Button {
                    showImagePicker = true
                } label: {
                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundColor(AppColors.GreenAccent)
                }
                .disabled(viewModel.isSending)
                
                // Text field
                HStack {
                    TextField("Message...", text: $messageText, axis: .vertical)
                        .font(.body)
                        .foregroundColor(AppColors.TextPrimary)
                        .lineLimit(1...5)
                        .disabled(viewModel.isSending)
                    
                    if !messageText.isEmpty {
                        Button {
                            messageText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppColors.TextTertiary)
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.CardDark)
                .cornerRadius(20)
                
                // Send/Voice button
                if !messageText.isEmpty {
                    Button {
                        sendTextMessage()
                    } label: {
                        Image(systemName: viewModel.isSending ? "hourglass" : "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.GreenAccent)
                    }
                    .disabled(viewModel.isSending)
                } else {
                    Button {
                        if isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    } label: {
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.title2)
                            .foregroundColor(isRecording ? .red : AppColors.GreenAccent)
                    }
                    .disabled(viewModel.isSending)
                }
            }
            .padding()
            .background(AppColors.BackgroundGradientStart.opacity(0.95))
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(AppColors.GreenAccent)
            
            Text("Loading conversation...")
                .font(.caption)
                .foregroundColor(AppColors.TextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func sendTextMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        messageText = ""
        viewModel.sendTextMessage(text)
    }
    
    private func sendImage(_ image: UIImage) {
        selectedImage = nil
        viewModel.sendImageMessage(image)
    }
    
    private func startRecording() {
        do {
            _ = try audioRecorder.startRecording()
            isRecording = true
        } catch {
            print("❌ Failed to start recording: \(error)")
            viewModel.errorMessage = "Failed to start recording. Please check microphone permissions."
        }
    }
    
    private func stopRecording() {
        if let result = audioRecorder.stopRecording() {
            isRecording = false
            viewModel.sendAudioMessage(fileURL: result.url, duration: Int(result.duration))
        } else {
            isRecording = false
            viewModel.errorMessage = "Failed to save recording"
        }
    }
    
    private func scrollToBottom() {
        guard let lastMessage = viewModel.messages.last else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Message Row View

struct MessageRowView: View {
    let message: DirectMessage
    let isFromCurrentUser: Bool
    @ObservedObject var audioPlayer: AudioPlayerManager
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Sender name (only for received messages)
                if !isFromCurrentUser {
                    Text(message.senderId.displayName)
                        .font(.caption2)
                        .foregroundColor(AppColors.TextTertiary)
                        .padding(.horizontal, 12)
                }
                
                // Message content
                messageContent
                
                // Timestamp
                Text(formatTime(message.createdAt))
                    .font(.caption2)
                    .foregroundColor(AppColors.TextTertiary)
                    .padding(.horizontal, 12)
            }
            
            if !isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }
    
    @ViewBuilder
    private var messageContent: some View {
        switch message.messageType {
        case .text:
            textMessageBubble
        case .image:
            imageMessageBubble
        case .audio:
            audioMessageBubble
        }
    }
    
    private var textMessageBubble: some View {
        Text(message.content ?? "")
            .font(.body)
            .foregroundColor(isFromCurrentUser ? .white : AppColors.TextPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isFromCurrentUser ? AppColors.GreenAccent : AppColors.CardDark)
            )
    }
    
    private var imageMessageBubble: some View {
        Group {
            if let mediaUrl = message.mediaUrl,
               let url = URL(string: mediaUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: 250, maxHeight: 300)
                            .clipped()
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isFromCurrentUser ? AppColors.GreenAccent : AppColors.BorderColor, lineWidth: 1)
                            )
                    case .failure:
                        VStack {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(AppColors.TextTertiary)
                            Text("Failed to load")
                                .font(.caption)
                                .foregroundColor(AppColors.TextSecondary)
                        }
                        .frame(width: 250, height: 200)
                        .background(AppColors.CardDark)
                        .cornerRadius(12)
                    case .empty:
                        ProgressView()
                            .frame(width: 250, height: 200)
                            .background(AppColors.CardDark)
                            .cornerRadius(12)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Text("📷 Image")
                    .font(.body)
                    .foregroundColor(AppColors.TextSecondary)
                    .padding()
                    .background(AppColors.CardDark)
                    .cornerRadius(12)
            }
        }
    }
    
    private var audioMessageBubble: some View {
        HStack(spacing: 12) {
            // Play/pause button
            Button {
                if let mediaUrl = message.mediaUrl,
                   let url = URL(string: mediaUrl) {
                    Task {
                        do {
                            try await audioPlayer.play(url: url, messageId: message.id)
                        } catch {
                            print("❌ Failed to play audio: \(error)")
                        }
                    }
                }
            } label: {
                let isCurrentlyPlaying = audioPlayer.isPlaying && audioPlayer.currentlyPlayingId == message.id
                Image(systemName: isCurrentlyPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(isFromCurrentUser ? .white : AppColors.GreenAccent)
            }
            
            // Waveform placeholder
            HStack(spacing: 2) {
                ForEach(0..<20, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isFromCurrentUser ? Color.white.opacity(0.7) : AppColors.GreenAccent.opacity(0.7))
                        .frame(width: 2, height: CGFloat.random(in: 8...24))
                }
            }
            
            // Duration
            if let duration = message.duration {
                Text(formatDuration(duration))
                    .font(.caption)
                    .foregroundColor(isFromCurrentUser ? .white : AppColors.TextSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isFromCurrentUser ? AppColors.GreenAccent : AppColors.CardDark)
        )
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
