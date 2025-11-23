//
//  ChatView.swift
//  VIBRA
//

import SwiftUI

struct ChatView: View {
    @StateObject private var vm: ChatsViewModel
    @State private var inputText: String = ""

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
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
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

    private func messageRow(_ msg: ChatMessage) -> some View {
        if msg.isSystem {
            return AnyView(
                Text(msg.content ?? "")
                    .font(.caption)
                    .foregroundColor(AppColors.TextSecondary)
                    .padding(6)
                    .background(AppColors.CardGlass)
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity, alignment: .center)
            )
        }

        let isMe = vm.isFromCurrentUser(msg)

        return AnyView(
            HStack {
                if isMe { Spacer(minLength: 40) }

                VStack(alignment: .leading, spacing: 4) {
                    if let text = msg.content, !text.isEmpty {
                        Text(text)
                            .font(.subheadline)
                            .foregroundColor(isMe ? .black : AppColors.TextPrimary)
                    } else if msg.type == .image {
                        Text("[Image]")
                            .font(.caption)
                            .foregroundColor(AppColors.TextSecondary)
                    } else {
                        Text("[\(msg.type.rawValue)]")
                            .font(.caption)
                            .foregroundColor(AppColors.TextSecondary)
                    }

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

                if !isMe { Spacer(minLength: 40) }
            }
        )
    }

    private func timeString(from date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    // MARK: - Typing indicator

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

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Écrire un message…", text: $inputText, axis: .vertical)
                .lineLimit(1...4)
                .padding(8)
                .background(AppColors.CardGlass)
                .cornerRadius(16)
                .foregroundColor(AppColors.TextPrimary)

            Button {
                let text = inputText
                inputText = ""
                vm.sendText(text)
            } label: {
                Image(systemName: vm.isSending ? "paperplane.fill" : "paperplane")
                    .foregroundColor(AppColors.GreenAccent)
                    .padding(8)
            }
            .disabled(vm.isSending || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            Color.black.opacity(0.4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
