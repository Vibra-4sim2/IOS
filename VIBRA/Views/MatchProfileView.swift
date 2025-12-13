//
//  MatchProfileView.swift
//  VIBRA
//
//  Vue du profil d'un match avec informations de compatibilité
//

import SwiftUI

struct MatchProfileView: View {
    @Environment(\.dismiss) private var dismiss
    let match: UserMatch

    @StateObject private var viewModel: MatchProfileViewModel

    init(match: UserMatch) {
        self.match = match
        _viewModel = StateObject(wrappedValue: MatchProfileViewModel(userId: match.userId))
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
                        headerSection
                        compatibilityBanner
                        profileHeader(for: user)
                            .padding(.horizontal)
                        statsRow
                            .padding(.horizontal)
                        actionButtons
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
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .task {
            await viewModel.loadProfile()
        }
    }

    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.TextPrimary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(AppColors.CardDark))
            }

            Spacer()

            Text("Profil du match")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColors.TextPrimary)

            Spacer()

            Circle()
                .fill(Color.clear)
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    private var compatibilityBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(getMatchQualityColor(similarity: match.similarity).opacity(0.2))
                    .frame(width: 50, height: 50)

                Text(match.similarityPercent)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(getMatchQualityColor(similarity: match.similarity))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Compatibilité")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.TextPrimary)

                Text(getMatchQualityText(similarity: match.similarity))
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.TextSecondary)
            }

            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 24))
                .foregroundColor(getMatchQualityColor(similarity: match.similarity))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.CardDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(getMatchQualityColor(similarity: match.similarity).opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }

    private func profileHeader(for user: User) -> some View {
        VStack(spacing: 10) {
            avatarView(urlString: user.avatar)
                .frame(width: 96, height: 96)

            VStack(spacing: 4) {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.TextPrimary)

                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(AppColors.TextSecondary)

                if viewModel.isLoadingRating {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Chargement du rating...")
                            .font(.caption2)
                            .foregroundColor(AppColors.TextSecondary)
                    }
                    .padding(.top, 4)
                } else if let rating = viewModel.rating {
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
                } else {
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

    private var actionButtons: some View {
        HStack(spacing: 12) {
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

            Button {
                // TODO: Implement messaging
            } label: {
                HStack {
                    Image(systemName: "message")
                    Text("Message")
                }
                .font(.subheadline.weight(.semibold))
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(AppColors.CardGlass)
                .foregroundColor(AppColors.TextPrimary)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.DividerColor, lineWidth: 0.8))
            }
        }
    }

    private var segmentBar: some View {
        HStack(spacing: 10) {
            segmentButton(title: "Sorties", isSelected: viewModel.selectedSegment == .mesSorties) {
                viewModel.selectedSegment = .mesSorties
            }
            segmentButton(title: "Créées", isSelected: viewModel.selectedSegment == .creees) {
                viewModel.selectedSegment = .creees
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
            case .creees:
                if viewModel.createdRides.isEmpty {
                    emptySection(text: "Aucune sortie créée")
                } else {
                    ForEach(viewModel.createdRides, id: \.ride.id) { item in
                        NavigationLink(destination: SortieDetailView(ride: item.ride, creator: item.creator)) {
                            RideCardView(item: item)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            case .publications:
                if viewModel.publications.isEmpty {
                    emptySection(text: "Aucune publication")
                } else {
                    ForEach(viewModel.publications) { pub in
                        PostCardView(
                            publication: pub,
                            initialIsLiked: false,
                            onLikeClick: {},
                            onCommentClick: {},
                            onShareClick: {},
                            onMenuClick: {}
                        )
                    }
                }
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
                            .overlay(ProgressView().tint(AppColors.GreenAccent))
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

    private func getMatchQualityColor(similarity: Double) -> Color {
        switch similarity {
        case 0.25...1.0:
            return AppColors.SuccessGreen
        case 0.15..<0.25:
            return AppColors.GreenAccent
        case 0.10..<0.15:
            return AppColors.WarningOrange
        default:
            return AppColors.TextTertiary
        }
    }

    private func getMatchQualityText(similarity: Double) -> String {
        switch similarity {
        case 0.25...1.0:
            return "Excellent match"
        case 0.15..<0.25:
            return "Bon match"
        case 0.10..<0.15:
            return "Match possible"
        default:
            return "Match faible"
        }
    }
}

#Preview {
    NavigationStack {
        MatchProfileView(match: UserMatch(
            userId: "123",
            similarity: 0.205,
            similarityPercent: "20.5%",
            distance: 3.86,
            user: MatchedUser(
                id: "123",
                firstName: "John",
                lastName: "Doe",
                email: "john@example.com",
                avatar: "",
                gender: "MALE"
            ),
            matchedPreferences: MatchedPreferences(
                level: PreferenceMatch(value: "BEGINNER", match: true),
                cyclingType: PreferenceMatch(value: "VTT", match: true),
                cyclingFrequency: nil,
                hikeType: nil,
                hikeDuration: nil,
                hikePreference: nil,
                campingPractice: nil,
                campingType: nil
            )
        ))
    }
}
