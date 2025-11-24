//
//  ChatsListView.swift
//  VIBRA
//
//  Liste des chats (sorties de l'utilisateur)
//

import SwiftUI

struct ChatsListView: View {
    @StateObject private var vm = ChatsViewModel(mode: .list)

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

                    if vm.isLoadingList {
                        VStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(AppColors.GreenAccent)
                            Text("Chargement de vos chats…")
                                .font(.caption)
                                .foregroundColor(AppColors.TextSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    } else if let err = vm.listErrorMessage {
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
                                                ChatView(sortieId: sortieId, sortieTitle: sortie.titre)
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
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mes chats")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.TextPrimary)

                Text("Conversations liées à tes sorties")
                    .font(.caption)
                    .foregroundColor(AppColors.TextSecondary)
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.caption)
                    .foregroundColor(.black)
                Text("\(vm.acceptedChats.count)")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppColors.GreenAccent)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    // MARK: - Row

    private func chatRow(participation: Participation, sortie: ParticipationSortie) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar de la sortie
            ZStack {
                Circle()
                    .fill(AppColors.CardGlass)
                Text(sortie.titre?.prefix(1).uppercased() ?? "S")
                    .font(.headline.bold())
                    .foregroundColor(AppColors.TextPrimary)
            }
            .frame(width: 44, height: 44)
            .overlay(
                Circle()
                    .stroke(AppColors.DividerColor, lineWidth: 0.8)
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(sortie.titre ?? "Sortie")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppColors.TextPrimary)
                        .lineLimit(1)

                    Spacer()

                    // Date courte si dispo
                    if let dateText = participation.dateText {
                        Text(dateText)
                            .font(.caption2)
                            .foregroundColor(AppColors.TextTertiary)
                    }
                }

                if let desc = sortie.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(AppColors.TextSecondary)
                        .lineLimit(2)
                }

                // Ligne d’info en bas (ex: dernier message ou simple label)
                HStack(spacing: 6) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppColors.GreenAccent)

                    Text("Ouvrir la conversation")
                        .font(.caption2)
                        .foregroundColor(AppColors.GreenAccent)

                    Spacer()
                }
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.CardDark.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColors.BorderColor, lineWidth: 0.6)
        )
        .shadow(color: AppColors.ShadowColor.opacity(0.5), radius: 5, x: 0, y: 3)
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
                vm.reloadList()
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
            Text("Tu n'as pas encore de conversations actives avec tes sorties.")
                .font(.caption)
                .foregroundColor(AppColors.TextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding()
    }
}

// MARK: - Petite extension pour la date si tu la veux
extension Participation {
    var dateText: String? {
        // Adapte selon ton modèle (ex: createdAt, updatedAt…)
        // Ici juste un placeholder : retourne nil si pas de date
        return nil
    }
}
