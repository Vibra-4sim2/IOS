//
//  ChatsListView.swift
//  VIBRA
//
//  Created by mac book pro on 11/23/25.
//
import SwiftUI

struct ChatsListView: View {
    @StateObject private var vm = ChatsViewModel()

    var body: some View {
        
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [AppColors.BackgroundGradientStart, AppColors.BackgroundGradientEnd]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    header

                    if vm.isLoading {
                        VStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(AppColors.GreenAccent)
                            Text("Chargement de vos chats…")
                                .font(.caption)
                                .foregroundColor(AppColors.TextSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    } else if let err = vm.errorMessage {
                        errorView(err)
                    } else if vm.userId == nil {
                        notLoggedInView
                    } else if vm.acceptedChats.isEmpty {
                        emptyView
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(vm.acceptedChats) { participation in
                                    if let sortie = participation.sortie,
                                       let sortieId = sortie.id {

                                        NavigationLink(
                                            destination: {
                                                // Si tu as un Ride complet, tu peux recréer un Ride minimal ici,
                                                // pour le moment on affiche juste un placeholder de détail
                                                ChatDetailPlaceholder(sortie: sortie)
                                            },
                                            label: {
                                                chatRow(participation: participation, sortie: sortie)
                                            }
                                        )
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                        }
                    }
                }
                .padding(.top, 12)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Mes chats")
                .font(.headline.weight(.semibold))
                .foregroundColor(AppColors.TextPrimary)

            Spacer()

            Text("\(vm.acceptedChats.count)")
                .font(.caption2.weight(.bold))
                .foregroundColor(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppColors.GreenAccent)
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }

    // MARK: - Row

    private func chatRow(participation: Participation, sortie: ParticipationSortie) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar circulaire avec première lettre du titre
            Circle()
                .fill(AppColors.CardGlass)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(sortie.titre?.prefix(1).uppercased() ?? "S")
                        .font(.headline.bold())
                        .foregroundColor(AppColors.TextPrimary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(sortie.titre ?? "Sortie")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppColors.TextPrimary)
                    .lineLimit(1)

                if let desc = sortie.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(AppColors.TextSecondary)
                        .lineLimit(2)
                }

                Text(participation.status ?? "")
                    .font(.caption2)
                    .foregroundColor(AppColors.GreenAccent)
            }

            Spacer()
        }
        .padding(10)
        .background(AppColors.CardDark.opacity(0.9))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.BorderColor, lineWidth: 0.6)
        )
    }

    // MARK: - States

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text("Erreur de chargement")
                .foregroundColor(.red)
                .font(.headline)
            Text(error)
                .font(.caption)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
            Button {
                Task { await vm.load() }
            } label: {
                Text("Réessayer")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(AppColors.GreenAccent)
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding()
    }

    private var notLoggedInView: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(AppColors.TextTertiary)
            Text("Non connecté")
                .font(.headline)
                .foregroundColor(AppColors.TextPrimary)
            Text("Connecte-toi pour voir les chats de tes sorties.")
                .font(.caption)
                .foregroundColor(AppColors.TextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.largeTitle)
                .foregroundColor(AppColors.TextTertiary)
            Text("Aucun chat")
                .font(.headline)
                .foregroundColor(AppColors.TextPrimary)
            Text("Tu n'as pas encore de sorties acceptées avec un chat.")
                .font(.caption)
                .foregroundColor(AppColors.TextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding()
    }
}

// Placeholder pour la page détail de chat (en attendant la vraie implémentation)
struct ChatDetailPlaceholder: View {
    let sortie: ParticipationSortie

    var body: some View {
        VStack(spacing: 12) {
            Text(sortie.titre ?? "Chat")
                .font(.title2.weight(.semibold))
                .foregroundColor(AppColors.TextPrimary)
            Text("Ici on mettra le chat pour cette sortie.")
                .font(.caption)
                .foregroundColor(AppColors.TextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [AppColors.BackgroundGradientStart, AppColors.BackgroundGradientEnd]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ChatsListView()
        .preferredColorScheme(.dark)
}
