//
//  MyRidesHomeView.swift
//  VIBRA
//
//  Created by mac book pro on 11/22/25.
//
import SwiftUI

struct MyRidesHomeView: View {
    @StateObject private var viewModel = MyRidesViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // Même background que HomeView
                LinearGradient(
                    gradient: Gradient(colors: [AppColors.BackgroundGradientStart, AppColors.BackgroundGradientEnd]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    // Barre de recherche sur MES sorties
                    searchBar

                    headerInfo

                    ScrollView {
                        LazyVStack(spacing: 20) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.GreenAccent))
                                    .padding()
                                Text("Chargement de mes sorties...")
                                    .foregroundColor(AppColors.TextSecondary)
                                    .font(.caption)
                            } else if let error = viewModel.errorMessage {
                                errorStateView(error: error)
                            } else if viewModel.currentUserId == nil {
                                notLoggedInState
                            } else if viewModel.myItems.isEmpty {
                                emptyStateView
                            } else {
                                Text("✅ \(viewModel.myItems.count) sortie(s) créée(s) par moi")
                                    .foregroundColor(AppColors.GreenAccent)
                                    .font(.caption)
                                    .padding(.bottom, 5)

                                ForEach(viewModel.myItems, id: \.ride.id) { item in
                                    NavigationLink(
                                        destination: SortieDetailView(ride: item.ride, creator: item.creator)
                                    ) {
                                        RideCardView(item: item)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 90)
                    }
                }
                .padding(.top, 10)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.TextSecondary)

            TextField("Rechercher dans mes sorties...", text: $viewModel.searchText)
                .foregroundColor(AppColors.TextPrimary)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.TextSecondary.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppColors.CardGlass)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.DividerColor, lineWidth: 0.8)
        )
        .shadow(color: AppColors.ShadowColor.opacity(0.8), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }

    // MARK: - Header
    private var headerInfo: some View {
        HStack {
            Text("Mes sorties")
                .font(.headline.weight(.semibold))
                .foregroundColor(AppColors.TextPrimary)

            Spacer()

            if let userId = viewModel.currentUserId {
                Text("User: \(userId)")
                    .font(.caption2)
                    .foregroundColor(AppColors.TextSecondary)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Error State
    @ViewBuilder
    private func errorStateView(error: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text("Erreur de chargement")
                .foregroundColor(.red)
                .font(.headline)
            Text(error)
                .foregroundColor(.red)
                .font(.caption)
                .multilineTextAlignment(.center)
            Button {
                Task { await viewModel.load() }
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
        .padding()
        .background(AppColors.CardDark.opacity(0.9))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.BorderColor, lineWidth: 0.6)
        )
        .padding(.top, 40)
    }

    // MARK: - Not Logged In
    private var notLoggedInState: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(AppColors.TextTertiary)
            Text("Non connecté")
                .foregroundColor(AppColors.TextPrimary)
                .font(.headline)
            Text("Connecte-toi pour voir tes propres sorties.")
                .foregroundColor(AppColors.TextSecondary)
                .font(.caption)
        }
        .padding()
        .background(AppColors.CardDark.opacity(0.9))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.BorderColor, lineWidth: 0.6)
        )
        .padding(.top, 40)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray.fill")
                .font(.largeTitle)
                .foregroundColor(AppColors.TextTertiary)
            Text("Aucune sortie créée")
                .foregroundColor(AppColors.TextPrimary)
                .font(.headline)
            Text("Tu n'as pas encore créé de sortie ou aucune ne correspond à ta recherche.")
                .foregroundColor(AppColors.TextSecondary)
                .font(.caption)
        }
        .padding()
        .background(AppColors.CardDark.opacity(0.9))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.BorderColor, lineWidth: 0.6)
        )
        .padding(.top, 40)
    }
}

#Preview {
    MyRidesHomeView()
        .preferredColorScheme(.dark)
}
