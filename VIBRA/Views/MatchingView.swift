//
//  MatchingView.swift
//  VIBRA
//
//  Vue principale pour afficher les matches
//

import SwiftUI

struct MatchingView: View {
    @StateObject private var viewModel = MatchingViewModel()
    @State private var selectedMatch: UserMatch?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [AppColors.BackgroundGradientStart, AppColors.BackgroundGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header avec bouton retour
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Retour")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(AppColors.GreenAccent)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Header
                    headerSection
                    
                    // Content
                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.errorMessage {
                        errorView(error)
                    } else if viewModel.matches.isEmpty {
                        emptyStateView
                    } else {
                        matchesList
                    }
                }
                .padding()
            }
            .refreshable {
                await viewModel.refreshMatches()
            }
        }
        .task {
            await viewModel.loadMatches()
        }
        .onDisappear {
            viewModel.cancelLoading()
        }
        // IMPORTANT: NavigationStack around the sheet so NavigationLink inside MatchDetailView can push ProfileView
        .sheet(item: $selectedMatch) { match in
            NavigationStack {
                MatchDetailView(match: match)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vos Matches")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.TextPrimary)
                    
                    if !viewModel.matches.isEmpty {
                        Text("\(viewModel.totalMatches) personnes compatibles")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.TextSecondary)
                    }
                }
                
                Spacer()
                
                // Algorithm badge
                if !viewModel.algorithm.isEmpty {
                    VStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.GreenAccent)
                        
                        Text("IA")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppColors.GreenAccent)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.CardDark)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.GreenAccent.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
    
    // MARK: - Matches List
    private var matchesList: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.matches) { match in
                MatchCard(match: match, viewModel: viewModel)
                    .onTapGesture {
                        selectedMatch = match
                    }
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(AppColors.GreenAccent)
                .scaleEffect(1.5)
            
            Text("Recherche de vos matches...")
                .font(.system(size: 16))
                .foregroundColor(AppColors.TextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Error View
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(AppColors.ErrorRed)
            
            Text(error)
                .font(.system(size: 16))
                .foregroundColor(AppColors.TextSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    await viewModel.refreshMatches()
                }
            }) {
                Text("Réessayer")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.TextPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.GreenAccent)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(AppColors.TextTertiary)
            
            Text("Aucun match trouvé")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppColors.TextPrimary)
            
            Text("Complétez votre profil pour trouver des personnes compatibles avec vos préférences")
                .font(.system(size: 14))
                .foregroundColor(AppColors.TextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Match Card
struct MatchCard: View {
    let match: UserMatch
    let viewModel: MatchingViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with avatar and info
            HStack(spacing: 16) {
                // Avatar
                Group {
                    if let avatarURL = match.user.avatarURL {
                        AsyncImage(url: avatarURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ZStack {
                                AppColors.CardDark
                                ProgressView()
                                    .tint(AppColors.GreenAccent)
                            }
                        }
                    } else {
                        ZStack {
                            AppColors.CardDark
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppColors.TextTertiary)
                        }
                    }
                }
                .frame(width: 70, height: 70)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(AppColors.GreenAccent.opacity(0.3), lineWidth: 2)
                )
                
                // User Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(match.user.fullName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.TextPrimary)
                    
                    HStack(spacing: 8) {
                        // Gender icon
                        Image(systemName: match.user.gender.lowercased() == "male" ? "person.fill" : "person.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.TextSecondary)
                        
                        // Match percentage
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text(match.similarityPercent)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(viewModel.getMatchQualityColor(similarity: match.similarity))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(viewModel.getMatchQualityColor(similarity: match.similarity).opacity(0.2))
                        )
                    }
                    
                    Text(viewModel.getMatchQualityText(similarity: match.similarity))
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.TextTertiary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.TextTertiary)
            }
            .padding(16)
            
            Divider()
                .background(AppColors.DividerColor)
            
            // Matching preferences
            VStack(alignment: .leading, spacing: 12) {
                Text("Préférences communes")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.TextSecondary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    PreferenceTag(title: "Niveau", isMatch: match.matchedPreferences.level?.match ?? false)
                    PreferenceTag(title: "Vélo", isMatch: match.matchedPreferences.cyclingType?.match ?? false)
                    PreferenceTag(title: "Randonnée", isMatch: match.matchedPreferences.hikeType?.match ?? false)
                    PreferenceTag(title: "Camping", isMatch: match.matchedPreferences.campingPractice?.match ?? false)
                }
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.CardDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.BorderColor, lineWidth: 1)
                )
                .shadow(color: AppColors.ShadowColor, radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Preference Tag
struct PreferenceTag: View {
    let title: String
    let isMatch: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(isMatch ? AppColors.SuccessGreen : AppColors.TextTertiary.opacity(0.5))
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(isMatch ? AppColors.TextPrimary : AppColors.TextTertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isMatch ? AppColors.SuccessGreen.opacity(0.15) : AppColors.CardOverlay)
        )
    }
}

// MARK: - Preview
#Preview {
    MatchingView()
}
