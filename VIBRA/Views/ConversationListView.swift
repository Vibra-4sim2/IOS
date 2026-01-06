//
//  ConversationListView.swift
//  VIBRA
//
//  List of private conversations
//

import SwiftUI

struct ConversationListView: View {
    @StateObject private var viewModel = ConversationListViewModel()
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [AppColors.BackgroundGradientStart, AppColors.BackgroundGradientEnd]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    header
                        .padding()
                    
                    // Content
                    if viewModel.isLoading && viewModel.conversations.isEmpty {
                        loadingView
                    } else if viewModel.conversations.isEmpty {
                        emptyView
                    } else {
                        conversationsList
                    }
                }
            }
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
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Messages")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.TextPrimary)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(viewModel.isConnected ? "Connected" : "Offline")
                        .font(.caption)
                        .foregroundColor(AppColors.TextSecondary)
                }
            }
            
            Spacer()
            
            if !viewModel.conversations.isEmpty {
                Text("\(viewModel.conversations.count)")
                    .font(.caption.bold())
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppColors.GreenAccent)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Conversations List
    
    private var conversationsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.conversations) { conversation in
                    NavigationLink(destination: PrivateChatView(conversationId: conversation.conversationId, conversation: conversation)) {
                        ConversationRowView(conversation: conversation)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .refreshable {
            viewModel.refresh()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(AppColors.TextTertiary)
            
            Text("No Messages")
                .font(.title3.bold())
                .foregroundColor(AppColors.TextPrimary)
            
            Text("Start a conversation by visiting a user's profile and tapping 'Send Message'")
                .font(.subheadline)
                .foregroundColor(AppColors.TextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                viewModel.refresh()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.GreenAccent)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Loading State
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(AppColors.GreenAccent)
            
            Text("Loading conversations...")
                .font(.caption)
                .foregroundColor(AppColors.TextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Conversation Row View

struct ConversationRowView: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                if let avatarUrl = conversation.otherUser.avatar,
                   let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                        case .failure, .empty:
                            Circle()
                                .fill(AppColors.CardGlass)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Text(conversation.otherUser.displayName.prefix(1).uppercased())
                                        .font(.title3.bold())
                                        .foregroundColor(AppColors.TextPrimary)
                                )
                        @unknown default:
                            Circle()
                                .fill(AppColors.CardGlass)
                                .frame(width: 56, height: 56)
                        }
                    }
                } else {
                    Circle()
                        .fill(AppColors.CardGlass)
                        .frame(width: 56, height: 56)
                    
                    Text(conversation.otherUser.displayName.prefix(1).uppercased())
                        .font(.title3.bold())
                        .foregroundColor(AppColors.TextPrimary)
                }
            }
            .overlay(
                Circle()
                    .stroke(AppColors.GreenAccent.opacity(0.3), lineWidth: 2)
            )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUser.displayName)
                        .font(.headline)
                        .foregroundColor(AppColors.TextPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(formatDate(conversation.updatedAt))
                        .font(.caption2)
                        .foregroundColor(AppColors.TextTertiary)
                }
                
                if let lastMessage = conversation.lastMessage {
                    HStack {
                        Text(messagePreview(lastMessage))
                            .font(.subheadline)
                            .foregroundColor(AppColors.TextSecondary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if conversation.unreadCount > 0 {
                            Text("\(conversation.unreadCount)")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.CardDark.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.BorderColor, lineWidth: 0.5)
        )
    }
    
    private func messagePreview(_ message: DirectMessage) -> String {
        switch message.messageType {
        case .text:
            return message.content ?? ""
        case .image:
            return "📷 Photo"
        case .audio:
            return "🎤 Voice message"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yy"
            return formatter.string(from: date)
        }
    }
}
