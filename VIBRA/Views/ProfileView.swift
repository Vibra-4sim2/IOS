//
//  ProfileView.swift
//  VIBRA
//
//  Created by mac book pro on 11/9/25.
//

import SwiftUI

struct ProfileView: View {
    // Optional userId: if nil, shows current user; if provided, shows that user's profile
    let userId: String?

    @StateObject private var viewModel: ProfileViewModel

    init(userId: String? = nil) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: ProfileViewModel(viewedUserId: userId))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [AppColors.BackgroundGradientStart, AppColors.BackgroundGradientEnd]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.GreenAccent))
            } else if let user = viewModel.user {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        profileHeader(for: user)
                            .padding(.horizontal)
                            .padding(.top, 12)

                        statsRow
                            .padding(.horizontal)

                        actionButtons(isCurrentUser: userId == nil)
                            .padding(.horizontal)

                        segmentBar
                            .padding(.horizontal)

                        contentSection
                            .padding(.horizontal)
                            .padding(.bottom, 24)
                    }
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Réessayer") {
                        Task { await viewModel.loadProfile() }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(AppColors.GreenAccent)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                }
                .padding()
            } else {
                VStack {
                    Text("Aucun profil trouvé")
                        .foregroundColor(.white)
                    Button("Charger") {
                        Task { await viewModel.loadProfile() }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.loadProfile()
        }
    }

    // MARK: - Subviews
    private func profileHeader(for user: User) -> some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                avatarView(urlString: user.avatar)
                    .frame(width: 96, height: 96)

                if userId == nil {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 12, weight: .bold))
                        .padding(6)
                        .background(AppColors.GreenAccent)
                        .clipShape(Circle())
                        .offset(x: 4, y: 4)
                }
            }

            VStack(spacing: 4) {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.TextPrimary)

                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(AppColors.TextSecondary)
                
                // DEBUG: Show rating loading state
                if viewModel.isLoadingRating {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Chargement du rating...")
                            .font(.caption2)
                            .foregroundColor(AppColors.TextSecondary)
                    }
                    .padding(.top, 4)
                }
                
                // Rating stars
                if let rating = viewModel.rating {
                    HStack(spacing: 6) {
                        StarRatingView(rating: rating.average, size: 18, color: AppColors.GreenAccent)
                        Text(String(format: "%.1f", rating.average))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.TextPrimary)
                        Text("(\(rating.count))")
                            .font(.caption)
                            .foregroundColor(AppColors.TextSecondary)
                    }
                    .padding(.top, 4)
                } else if !viewModel.isLoadingRating {
                    // DEBUG: Show if no rating
                    Text("Pas encore de notes")
                        .font(.caption2)
                        .foregroundColor(AppColors.TextTertiary)
                        .padding(.top, 4)
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(AppColors.GreenAccent)
                    .font(.caption)
                Text("Tunisia")
                    .font(.caption)
                    .foregroundColor(AppColors.TextSecondary)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 18) {
            statItem(title: "sorties", value: viewModel.sortiesCount)
            statItem(title: "posts", value: viewModel.publicationsCount)
            statItem(title: "followers", value: viewModel.followersCount)
            statItem(title: "following", value: viewModel.followingCount)
        }
        .padding(14)
        .background(AppColors.CardDark.opacity(0.95))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColors.BorderColor, lineWidth: 0.6)
        )
    }

    private func statItem(title: String, value: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.TextPrimary)
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.TextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func actionButtons(isCurrentUser: Bool) -> some View {
        HStack(spacing: 12) {
            if isCurrentUser {
                NavigationLink(destination: ProfileUpdateView()) {
                    HStack {
                        Image(systemName: "square.and.pencil")
                        Text("Modifier le profil")
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(AppColors.CardGlass)
                    .foregroundColor(AppColors.TextPrimary)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.DividerColor, lineWidth: 0.8))
                }
            } else {
                Button {
                    Task { await viewModel.toggleFollow() }
                } label: {
                    HStack {
                        Image(systemName: viewModel.isFollowing ? "checkmark" : "plus")
                        Text(viewModel.isFollowing ? "Suivi" : "Suivre")
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [AppColors.GreenAccent, AppColors.GreenDark]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.black)
                    .cornerRadius(14)
                }
                .disabled(viewModel.isFollowLoading)
            }
            if !isCurrentUser, let otherUserId = userId {
                NavigationLink(destination: PrivateChatView(recipientId: otherUserId)) {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Message")
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [AppColors.GreenAccent.opacity(0.3), AppColors.GreenDark.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(AppColors.GreenAccent)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.GreenAccent.opacity(0.5), lineWidth: 1))
                }
            }
        }
    }

    private var segmentBar: some View {
        HStack(spacing: 10) {
            segmentButton(title: "Sorties", isSelected: viewModel.selectedSegment == .mesSorties) {
                viewModel.selectedSegment = .mesSorties
            }
            segmentButton(title: "Publications", isSelected: viewModel.selectedSegment == .publications) {
                viewModel.selectedSegment = .publications
            }
        }
    }

    private func segmentButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
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
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.DividerColor, lineWidth: 0.8))
        }
    }

    private var contentSection: some View {
        VStack(spacing: 12) {
            switch viewModel.selectedSegment {
            case .mesSorties:
                if viewModel.rides.isEmpty {
                    emptySection(text: "Aucune sortie trouvée")
                } else {
                    ForEach(viewModel.rides, id: \.ride.id) { item in
                        NavigationLink(destination: SortieDetailView(ride: item.ride, creator: item.creator)) {
                            RideCardView(item: item)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            case .publications:
                if viewModel.publications.isEmpty {
                    emptySection(text: "Aucune publication trouvée")
                } else {
                    ForEach(viewModel.publications, id: \.id) { publication in
                        PostCardView(
                            publication: publication,
                            initialIsLiked: false,
                            onLikeClick: {},
                            onCommentClick: {},
                            onShareClick: {},
                            onMenuClick: {}
                        )
                    }
                }
            @unknown default:
                emptySection(text: "Unknown section")
            }
        }
    }

    private func emptySection(text: String) -> some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(AppColors.CardDark.opacity(0.95))
            .frame(height: 120)
            .overlay(
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(AppColors.TextSecondary)
            )
    }

    private func avatarView(urlString: String?) -> some View {
        Group {
            if let s = urlString, let url = URL(string: s), !s.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Circle().fill(AppColors.CardGlass)
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Circle().fill(AppColors.CardGlass)
                            .overlay(Image(systemName: "person.fill").foregroundColor(AppColors.TextTertiary))
                    @unknown default:
                        Circle().fill(AppColors.CardGlass)
                    }
                }
            } else {
                Circle()
                    .fill(AppColors.CardGlass)
                    .overlay(Image(systemName: "person.fill").foregroundColor(AppColors.TextTertiary))
            }
        }
        .clipShape(Circle())
        .overlay(Circle().stroke(AppColors.DividerColor, lineWidth: 1.2))
        .shadow(color: AppColors.ShadowColor, radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ProfileView()
    }
}
