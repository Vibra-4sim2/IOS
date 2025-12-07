//
//  ChatView.swift
//  VIBRA
//

import SwiftUI
import PhotosUI

struct ChatView: View {
    @StateObject private var vm: ChatsViewModel
    @State private var inputText: String = ""
    @State private var selectedPhoto: PhotosPickerItem?

    init(sortieId: String, sortieTitle: String?) {
        _vm = StateObject(wrappedValue: ChatsViewModel(mode: .chat(sortieId: sortieId, sortieTitle: sortieTitle)))
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider().background(AppColors.DividerColor)

            contentArea

            if vm.isSomeoneTyping {
                typingIndicator
            }

            inputBar
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [AppColors.BackgroundGradientStart, AppColors.BackgroundGradientEnd]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .onDisappear {
            vm.audioRecorder.cancelRecording()
            vm.audioPlayer.stop()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(vm.navigationTitle)
                .font(.headline.weight(.semibold))
                .foregroundColor(AppColors.TextPrimary)
                .lineLimit(1)

            Spacer()

            Circle()
                .fill(vm.isWebSocketConnected ? AppColors.GreenAccent : AppColors.TextTertiary)
                .frame(width: 10, height: 10)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentArea: some View {
        if vm.isLoadingChat && vm.messages.isEmpty {
            VStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(AppColors.GreenAccent)
                Text("Chargement du chat…")
                    .font(.caption)
                    .foregroundColor(AppColors.TextSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = vm.chatErrorMessage, vm.messages.isEmpty {
            VStack(spacing: 8) {
                Text("Erreur")
                    .font(.headline)
                    .foregroundColor(.red)
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                Button("Réessayer") {
                    vm.reloadChatMessages()
                }
                .padding(8)
                .background(AppColors.GreenAccent)
                .foregroundColor(.black)
                .cornerRadius(8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else {
            messagesList
        }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(vm.messages) { msg in
                        messageRow(msg)
                            .id(msg.id)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .onChange(of: vm.messages.count) { _ in
                scrollToBottom(proxy: proxy, animated: true)
            }
            .onAppear {
                scrollToBottom(proxy: proxy, animated: false)
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        guard let lastId = vm.messages.last?.id else { return }
        if animated {
            withAnimation {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(lastId, anchor: .bottom)
        }
    }

    // MARK: - Helpers avatar & nom

    private func displayName(for msg: ChatMessage) -> String? {
        if let user = msg.sender, !user.displayName.isEmpty {
            return user.displayName
        }
        return nil
    }

    @ViewBuilder
    private func avatarView(for msg: ChatMessage, isMe: Bool) -> some View {
        if let user = msg.sender,
           let urlString = user.avatar,
           let url = URL(string: urlString) {

            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 32, height: 32)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                case .failure(_):
                    placeholderAvatar(initial: user.firstName?.first)
                @unknown default:
                    placeholderAvatar(initial: user.firstName?.first)
                }
            }
            .frame(width: 32, height: 32)
        } else {
            let initial = msg.sender?.firstName?.first
            placeholderAvatar(initial: initial)
        }
    }

    private func placeholderAvatar(initial: Character?) -> some View {
        let letter = initial.map { String($0).uppercased() } ?? "?"
        return Circle()
            .fill(AppColors.CardGlass)
            .frame(width: 32, height: 32)
            .overlay(
                Text(letter)
                    .font(.caption)
                    .foregroundColor(AppColors.TextPrimary)
            )
    }

    // MARK: - Message Row

    private func messageRow(_ msg: ChatMessage) -> some View {
        Group {
            if msg.isSystem {
                Text(msg.content ?? "")
                    .font(.caption)
                    .foregroundColor(AppColors.TextSecondary)
                    .padding(6)
                    .background(AppColors.CardGlass)
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                let isMe = vm.isFromCurrentUser(msg)
                let name = displayName(for: msg)

                HStack(alignment: .bottom, spacing: 8) {
                    if !isMe {
                        avatarView(for: msg, isMe: isMe)
                    } else {
                        Spacer(minLength: 40)
                    }

                    VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                        if !isMe, let name = name {
                            Text(name)
                                .font(.caption2)
                                .foregroundColor(AppColors.TextTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            // Contenu du message
                            messageContentView(msg, isMe: isMe)
                            
                            // Timestamp
                            if let date = msg.createdDate {
                                Text(timeString(from: date))
                                    .font(.caption2)
                                    .foregroundColor(isMe ? Color.black.opacity(0.7) : AppColors.TextTertiary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        .padding(10)
                        .background(isMe ? AppColors.GreenAccent : AppColors.CardDark.opacity(0.9))
                        .cornerRadius(16)
                        .frame(maxWidth: .infinity, alignment: isMe ? .trailing : .leading)
                    }

                    if isMe {
                        avatarView(for: msg, isMe: isMe)
                    } else {
                        Spacer(minLength: 40)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func messageContentView(_ msg: ChatMessage, isMe: Bool) -> some View {
        switch msg.type {
        case .text:
            if let text = msg.content, !text.isEmpty {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(isMe ? .black : AppColors.TextPrimary)
            }
        case .image:
            imageMessageView(msg)
        case .audio:
            audioMessageView(msg, isMe: isMe)
        case .poll:
            if msg.poll != nil {
                PollMessageView(
                    message: msg,
                    currentUserId: vm.userId,
                    onVote: { optionIds in vm.vote(on: msg, optionIds: optionIds) },
                    onClose: { vm.closePoll(message: msg) },
                    onShowVoters: { optionId in
                        print("Voir les votants pour option:", optionId)
                    }
                )
            } else {
                Text("[Sondage non disponible]")
                    .font(.caption)
                    .foregroundColor(AppColors.TextSecondary)
            }
        default:
            Text("[\(msg.type.displayName)]")
                .font(.caption)
                .foregroundColor(AppColors.TextSecondary)
        }
    }
    
    private func imageMessageView(_ msg: ChatMessage) -> some View {
        Group {
            if let urlString = msg.mediaUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Rectangle()
                                .fill(AppColors.CardGlass)
                                .frame(width: 200, height: 200)
                            ProgressView()
                                .tint(AppColors.GreenAccent)
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: 240, maxHeight: 240)
                            .clipped()
                            .cornerRadius(12)
                    case .failure(_):
                        ZStack {
                            Rectangle()
                                .fill(AppColors.CardGlass)
                                .frame(width: 200, height: 200)
                            Text("Impossible de charger l'image")
                                .font(.caption)
                                .foregroundColor(AppColors.TextSecondary)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Text("[Image]")
                    .font(.caption)
                    .foregroundColor(AppColors.TextSecondary)
            }
        }
    }
    
    private func audioMessageView(_ msg: ChatMessage, isMe: Bool) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Bouton play/pause avec loading
                Button {
                    if let urlString = msg.mediaUrl, let url = URL(string: urlString) {
                        if vm.audioPlayer.isPlayingMessage(msg.id ?? "") {
                            vm.pauseAudio()
                        } else {
                            vm.playAudio(url: url, messageId: msg.id ?? "")
                        }
                    }
                } label: {
                    ZStack {
                        if vm.audioPlayer.isLoading && vm.audioPlayer.currentlyPlayingId == msg.id {
                            ProgressView()
                                .tint(isMe ? .black : AppColors.GreenAccent)
                        } else {
                            Image(systemName: vm.audioPlayer.isPlayingMessage(msg.id ?? "") ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(isMe ? .black : AppColors.GreenAccent)
                        }
                    }
                    .frame(width: 32, height: 32)
                }
                .disabled(vm.audioPlayer.isLoading)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Waveform placeholder
                    HStack(spacing: 2) {
                        ForEach(0..<20, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(isMe ? Color.black.opacity(0.3) : AppColors.TextSecondary)
                                .frame(width: 3, height: CGFloat.random(in: 8...24))
                        }
                    }
                    .frame(height: 24)
                    
                    // Durée
                    if let duration = msg.mediaDuration {
                        let currentTime = vm.audioPlayer.currentlyPlayingId == msg.id ? vm.audioPlayer.currentTime : 0
                        let displayTime = currentTime > 0 ? currentTime : duration
                        
                        Text(formatDuration(displayTime))
                            .font(.caption2)
                            .foregroundColor(isMe ? Color.black.opacity(0.7) : AppColors.TextTertiary)
                    }
                }
            }
            
            // Progress bar pour la lecture
            if vm.audioPlayer.currentlyPlayingId == msg.id, let duration = msg.mediaDuration, duration > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isMe ? Color.black.opacity(0.2) : AppColors.CardGlass)
                            .frame(height: 4)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isMe ? Color.black : AppColors.GreenAccent)
                            .frame(width: geometry.size.width * CGFloat(vm.audioPlayer.currentTime / duration), height: 4)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let progress = value.location.x / geometry.size.width
                                let newTime = Double(progress) * duration
                                vm.seekAudio(to: max(0, min(newTime, duration)))
                            }
                    )
                }
                .frame(height: 4)
            }
        }
        .frame(maxWidth: 240)
    }

    private func timeString(from date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - Typing & Input

    private var typingIndicator: some View {
        HStack {
            Text("Quelqu'un est en train d'écrire…")
                .font(.caption)
                .foregroundColor(AppColors.TextSecondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            // Recording indicator
            if vm.audioRecorder.isRecording {
                recordingIndicator
                    .onAppear {
                        print("📺 [ChatView] Recording indicator appeared")
                    }
            }
            
            HStack(spacing: 8) {
                // Bouton sondage
                Button {
                    vm.openPollSheet()
                } label: {
                    Image(systemName: "chart.bar.xaxis")
                        .foregroundColor(AppColors.GreenAccent)
                        .padding(8)
                }
                .disabled(vm.audioRecorder.isRecording || vm.isUploadingMedia)
                
                // Bouton image
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Image(systemName: "photo.on.rectangle")
                        .foregroundColor(vm.isUploadingMedia ? AppColors.TextTertiary : AppColors.GreenAccent)
                        .padding(8)
                }
                .disabled(vm.isUploadingMedia || vm.audioRecorder.isRecording)

                // Input texte ou bouton micro
                if vm.audioRecorder.isRecording {
                    // Mode enregistrement
                    recordingControls
                        .onAppear {
                            print("📺 [ChatView] Recording controls appeared")
                        }
                } else {
                    // Mode normal
                    TextField("Écrire un message…", text: $inputText, axis: .vertical)
                        .lineLimit(1...4)
                        .padding(8)
                        .background(AppColors.CardGlass)
                        .cornerRadius(16)
                        .foregroundColor(AppColors.TextPrimary)
                }

                // Bouton envoi ou micro
                if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !vm.audioRecorder.isRecording {
                    // Bouton micro
                    Button {
                        print("🔘 [ChatView] Micro button tapped")
                        print("🔘 [ChatView] isRecording:", vm.audioRecorder.isRecording)
                        print("🔘 [ChatView] hasPermission:", vm.audioRecorder.hasPermission)
                        
                        Task {
                            if !vm.audioRecorder.hasPermission {
                                print("🔘 [ChatView] Requesting permission...")
                                await vm.audioRecorder.requestPermission()
                            }
                            if vm.audioRecorder.hasPermission {
                                print("🔘 [ChatView] Starting recording...")
                                vm.startRecordingAudio()
                            } else {
                                print("❌ [ChatView] Permission denied")
                            }
                        }
                    } label: {
                        Image(systemName: "mic.fill")
                            .foregroundColor(AppColors.GreenAccent)
                            .padding(8)
                    }
                    .disabled(vm.audioRecorder.isRecording || vm.isUploadingMedia)
                } else if !vm.audioRecorder.isRecording {
                    // Bouton envoi texte
                    Button {
                        let text = inputText
                        inputText = ""
                        vm.sendText(text)
                    } label: {
                        Image(systemName: vm.isSending ? "paperplane.fill" : "paperplane")
                            .foregroundColor(AppColors.GreenAccent)
                            .padding(8)
                    }
                    .disabled(vm.isSending)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(
            Color.black.opacity(0.4)
                .ignoresSafeArea(edges: .bottom)
        )
        .onChange(of: selectedPhoto) { newValue in
            Task {
                await handleSelectedPhoto(newValue)
            }
        }
        .sheet(isPresented: $vm.isPresentingPollSheet) {
            PollCreationView(
                question: $vm.pollQuestion,
                options: $vm.pollOptions,
                allowMultiple: $vm.pollAllowMultiple,
                closesAt: $vm.pollClosesAt,
                onAddOption: { vm.addPollOptionField() },
                onRemoveOption: { vm.removePollOptionField(at: $0) },
                onCancel: { vm.resetPollDraft() },
                onCreate: {
                    vm.createPoll()
                }
            )
        }
    }
    
    private var recordingControls: some View {
        HStack {
            Button {
                vm.cancelRecordingAudio()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
            }
            
            Spacer()
            
            // Timer
            Text(formatDuration(vm.audioRecorder.recordingDuration))
                .font(.headline)
                .foregroundColor(AppColors.GreenAccent)
                .monospacedDigit()
            
            // Animation recording
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .opacity(vm.audioRecorder.isRecording ? 1 : 0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: vm.audioRecorder.isRecording)
            
            Spacer()
            
            Button {
                vm.sendRecordedAudio()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColors.GreenAccent)
                    .font(.title2)
            }
        }
        .padding(8)
        .background(AppColors.CardGlass)
        .cornerRadius(16)
    }
    
    private var recordingIndicator: some View {
        HStack {
            Image(systemName: "waveform")
                .foregroundColor(.red)
            Text("Enregistrement en cours...")
                .font(.caption)
                .foregroundColor(AppColors.TextSecondary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private func handleSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                let mimeType = "image/jpeg"
                let fileName = "photo-\(Int(Date().timeIntervalSince1970)).jpg"
                vm.sendImage(data: data, fileName: fileName, mimeType: mimeType)
            }
        } catch {
            print("❌ handleSelectedPhoto error:", error)
        }
        await MainActor.run {
            selectedPhoto = nil
        }
    }
}
