//
//  HomeView.swift
//  VIBRA
//
//  Created by mac book pro on 11/7/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showMatchingView = false

    var body: some View {
        NavigationStack {
            ZStack {
                // 🌌 Arrière-plan cohérent avec l'app
                LinearGradient(
                    gradient: Gradient(colors: [AppColors.BackgroundGradientStart, AppColors.BackgroundGradientEnd]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    // 🔍 Barre de recherche avec effet verre
                    searchBar

                    // 🎯 Bouton Matching (nouveau)
                    matchingButton

                    // 🚴‍♂️ Filtre activité (Randonnée / Vélo)
                    activityFilterBar

                    // 🔘 Boutons principaux (Followers / Recommendation / Explore)
                    mainFilterBar

                    // 📋 Liste des sorties
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.GreenAccent))
                                    .padding()
                                Text("Chargement des sorties...")
                                    .foregroundColor(AppColors.TextSecondary)
                                    .font(.caption)
                            } else if let error = viewModel.errorMessage {
                                errorStateView(error: error)
                            } else if viewModel.filteredItems.isEmpty {
                                emptyStateView
                            } else {
                                Text("✅ \(viewModel.filteredItems.count) sortie(s) trouvée(s)")
                                    .foregroundColor(AppColors.GreenAccent)
                                    .font(.caption)
                                    .padding(.bottom, 5)

                                ForEach(viewModel.filteredItems, id: \.ride.id) { item in
                                    NavigationLink(destination: SortieDetailView(ride: item.ride, creator: item.creator)) {
                                        RideCardView(item: item)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 90) // espace pour tabbar
                    }
                }
                .padding(.top, 10)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
            .task {
                print("🚀 HomeView: Appearing, about to load data...")
                await viewModel.load()
                print("✅ HomeView: Load completed. Items count: \(viewModel.items.count)")
            }
            .sheet(isPresented: $showMatchingView) {
                MatchingView()
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.TextSecondary)

            TextField("Rechercher une sortie, un lieu, un organisateur...", text: $viewModel.searchText)
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

            Image(systemName: "mic.fill")
                .foregroundColor(AppColors.TextSecondary)
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

    // MARK: - Matching Button (NEW)
    private var matchingButton: some View {
        Button(action: {
            showMatchingView = true
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.GreenAccent.opacity(0.3), AppColors.TealAccent.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.GreenAccent)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Découvrir vos matches")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.TextPrimary)
                    
                    Text("Trouvez des partenaires compatibles avec l'IA")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.TextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.GreenAccent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.CardDark)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [AppColors.GreenAccent.opacity(0.4), AppColors.TealAccent.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: AppColors.GlowGreen.opacity(0.5), radius: 12, x: 0, y: 4)
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Activity Filter (All / Randonnée / Vélo)
    private var activityFilterBar: some View {
        HStack(spacing: 10) {
            ActivityFilterButton(
                title: "All",
                isSelected: viewModel.selectedActivity == "All"
            ) {
                viewModel.selectedActivity = "All"
            }

            ActivityFilterButton(
                title: "Randonnée",
                isSelected: viewModel.selectedActivity == "Randonnée"
            ) {
                viewModel.selectedActivity = "Randonnée"
            }

            ActivityFilterButton(
                title: "Vélo",
                isSelected: viewModel.selectedActivity == "Vélo"
            ) {
                viewModel.selectedActivity = "Vélo"
            }

            Spacer()
        }
        .padding(.horizontal)
    }

    // MARK: - Main Filter Bar (Followers / Recommendation / Explore)
    private var mainFilterBar: some View {
        HStack(spacing: 10) {
            FilterButton(
                title: "Followers",
                isSelected: viewModel.selectedTab == "Followers"
            ) {
                viewModel.selectedTab = "Followers"
                Task {
                    await viewModel.onTabChange()
                }
            }

            FilterButton(
                title: "Recommendation",
                isSelected: viewModel.selectedTab == "Recommendation"
            ) {
                viewModel.selectedTab = "Recommendation"
                Task {
                    await viewModel.onTabChange()
                }
            }

            FilterButton(
                title: "Explore",
                isSelected: viewModel.selectedTab == "Explore"
            ) {
                viewModel.selectedTab = "Explore"
                Task {
                    await viewModel.onTabChange()
                }
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

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: viewModel.selectedTab == "Recommendation" ? "star.fill" : "tray.fill")
                .font(.largeTitle)
                .foregroundColor(AppColors.TextTertiary)
            Text(viewModel.selectedTab == "Recommendation" ? "Aucune recommandation" : "Aucune sortie trouvée")
                .foregroundColor(AppColors.TextPrimary)
                .font(.headline)
            Text(viewModel.selectedTab == "Recommendation"
                 ? "Participe à plus de sorties pour obtenir des recommandations personnalisées"
                 : "Essaie de modifier ta recherche ou tes filtres")
                .foregroundColor(AppColors.TextSecondary)
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
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

// MARK: - Boutons filtres

struct FilterButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: isSelected
                                           ? [AppColors.GreenAccent, AppColors.GreenDark]
                                           : [AppColors.CardGlass, AppColors.CardGlass.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(isSelected ? .black : AppColors.TextSecondary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.DividerColor, lineWidth: 0.8)
                )
                .shadow(color: isSelected ? AppColors.GlowGreen.opacity(0.7) : AppColors.ShadowColor.opacity(0.3),
                        radius: 8, x: 0, y: 4)
        }
    }
}

struct ActivityFilterButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if title == "Randonnée" {
                    Image(systemName: "figure.hiking")
                        .font(.system(size: 13, weight: .semibold))
                } else if title == "Vélo" {
                    Image(systemName: "bicycle")
                        .font(.system(size: 13, weight: .semibold))
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                }

                Text(title)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                (isSelected
                 ? AnyShapeStyle(LinearGradient(
                        gradient: Gradient(colors: [AppColors.GreenAccent, AppColors.GreenDark]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                 : AnyShapeStyle(AppColors.CardGlass))
            )
            .cornerRadius(12)
            .foregroundColor(isSelected ? .black : AppColors.TextSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.DividerColor, lineWidth: 0.8)
            )
            .shadow(color: isSelected ? AppColors.GlowGreen.opacity(0.7) : AppColors.ShadowColor.opacity(0.3),
                    radius: 6, x: 0, y: 3)
        }
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
            .preferredColorScheme(.dark)
    }
}
