//
//  FeedView.swift
//  VIBRA
//
//  Created by mac book pro on 11/17/25.
//
import SwiftUI

// Couleurs équivalentes
private let BackgroundDark = Color(red: 0x0F/255, green: 0x0F/255, blue: 0x0F/255)
private let CardBackground = Color(red: 0x1A/255, green: 0x1A/255, blue: 0x1A/255)
private let GlassBackground = Color(red: 0x2A/255, green: 0x2A/255, blue: 0x2A/255).opacity(0.4)
private let GreenAccent = Color(red: 0x4A/255, green: 0xDE/255, blue: 0x80/255)
private let TextPrimary = Color.white
private let TextSecondary = Color(red: 0x9C/255, green: 0xA3/255, blue: 0xAF/255)

struct FeedView: View {

    @StateObject private var viewModel = FeedViewModel()

    /// Appelé quand l'utilisateur veut créer un post
    var onCreatePost: (() -> Void)?
    /// Appelé quand l'utilisateur veut ouvrir les détails / commentaires d'une publication
    var onOpenPost: ((PublicationResponse) -> Void)?

    // 🔥 Navigation interne vers l'écran d'ajout
    @State private var isShowingAddPublication = false

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundDark.ignoresSafeArea()

                content
                    .padding(.top, 8)
            }
            .refreshable {
                viewModel.refreshFeed()
            }
            .navigationBarHidden(true)
            // Navigation vers AddPublicationView
            .navigationDestination(isPresented: $isShowingAddPublication) {
                AddPublicationView()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.uiState {
        case .loading:
            if viewModel.publications.isEmpty {
                LoadingStateView()
            } else { feedList }
        case .success:
            feedList
        case .empty:
            // Bouton "Create Post" déclenche la navigation interne
            EmptyStateView(onCreatePost: {
                // Si un handler externe existe, on l'appelle en plus
                onCreatePost?()
                isShowingAddPublication = true
            })
        case .error(let message):
            ErrorStateView(message: message, onRetry: { viewModel.refreshFeed() })
        }
    }

    private var feedList: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Header : clique sur "What's on your mind?" → ouvre AddPublicationView
                FeedHeaderView(onCreatePost: {
                    onCreatePost?()
                    isShowingAddPublication = true
                })
                .padding(.top, 8)

                ForEach(viewModel.publications) { publication in
                    PostCardView(
                        publication: publication,
                        initialIsLiked: viewModel.isLikedByCurrentUser(publication),
                        onLikeClick: { viewModel.toggleLike(publicationId: publication.id) },
                        onCommentClick: { onOpenPost?(publication) }, // ouvre détails / commentaires
                        onShareClick: {},
                        onMenuClick: {}
                    )
                }

                Color.clear.frame(height: 40)
            }
            .padding(.horizontal, 12)
        }
    }
}



// MARK: - HEADER amélioré

struct FeedHeaderView: View {

    var onCreatePost: () -> Void

    var body: some View {
        VStack(spacing: 16) {

            // Titre simplifié
            HStack {
                Text("Feed")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(TextPrimary)

                Spacer()

                Image(systemName: "line.horizontal.3.decrease.circle")
                    .foregroundColor(GreenAccent)
                    .font(.system(size: 26))
            }
            .padding(.horizontal, 4)

            // Zone "What's on your mind"
            Button(action: onCreatePost) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 42, height: 42)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(TextSecondary)
                        )

                    Text("What's on your mind?")
                        .foregroundColor(TextSecondary)
                        .font(.system(size: 15))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Circle()
                        .fill(GreenAccent.opacity(0.20))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(GreenAccent)
                        )
                }
                .padding(14)
                .background(CardBackground.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
            }
        }
    }
}



// MARK: - POST CARD (léger clean)
struct PostCardView: View {

    let publication: PublicationResponse
    @State private var isLiked: Bool
    @State private var likesCount: Int

    var onLikeClick: () -> Void
    var onCommentClick: () -> Void
    var onShareClick: () -> Void
    var onMenuClick: () -> Void

    init(
        publication: PublicationResponse,
        initialIsLiked: Bool = false,
        onLikeClick: @escaping () -> Void = {},
        onCommentClick: @escaping () -> Void = {},
        onShareClick: @escaping () -> Void = {},
        onMenuClick: @escaping () -> Void = {}
    ) {
        self.publication = publication
        self._isLiked = State(initialValue: initialIsLiked)
        self._likesCount = State(initialValue: publication.likesCount)
        self.onLikeClick = onLikeClick
        self.onCommentClick = onCommentClick
        self.onShareClick = onShareClick
        self.onMenuClick = onMenuClick
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // HEADER
            HStack(spacing: 12) {
                avatarView

                VStack(alignment: .leading, spacing: 2) {
                    Text(publication.author?.fullName() ?? "Unknown User")
                        .foregroundColor(TextPrimary)
                        .font(.system(size: 16, weight: .semibold))

                    Text(formatTimestamp(publication.createdAt))
                        .foregroundColor(TextSecondary)
                        .font(.system(size: 12))
                }

                Spacer()

                Button(action: onMenuClick) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(TextSecondary)
                }
            }

            // CONTENT
            Text(publication.content)
                .foregroundColor(TextPrimary)
                .font(.system(size: 15))
                .lineSpacing(3)

            // IMAGE
            if publication.hasImage(),
               let urlString = publication.image,
               let url = URL(string: urlString) {

                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // TAGS
            if let tags = publication.tags, !tags.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(tags.prefix(3)), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 12))
                            .foregroundColor(GreenAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(GreenAccent.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            // LOCATION
            if let location = publication.location, !location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14))
                        .foregroundColor(TextSecondary)
                    Text(location)
                        .foregroundColor(TextSecondary)
                        .font(.system(size: 12))
                }
            }

            // STATS
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? GreenAccent : TextSecondary)
                    Text(formatNumber(likesCount))
                        .foregroundColor(TextSecondary)
                        .font(.system(size: 13))
                }

                Spacer()

                Text("\(publication.commentsCount) comments • \(publication.sharesCount) shares")
                    .foregroundColor(TextSecondary)
                    .font(.system(size: 13))
            }

            Divider().background(Color.white.opacity(0.06))

            // ACTIONS
            HStack {
                InteractionButtonView(
                    systemImage: isLiked ? "heart.fill" : "heart",
                    label: "Like",
                    tint: isLiked ? GreenAccent : TextSecondary
                ) {
                    isLiked.toggle()
                    likesCount += isLiked ? 1 : -1
                    onLikeClick()
                }

                InteractionButtonView(
                    systemImage: "bubble.left",
                    label: "Comment",
                    tint: TextSecondary,
                    action: onCommentClick
                )

                InteractionButtonView(
                    systemImage: "arrowshape.turn.up.right",
                    label: "Share",
                    tint: TextSecondary,
                    action: onShareClick
                )
            }

        }
        .padding(16)
        .background(CardBackground.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)
    }

    private var avatarView: some View {
        ZStack {
            Circle()
                .stroke(GreenAccent.opacity(0.3), lineWidth: 2)
                .frame(width: 48, height: 48)

            if let avatarUrl = publication.author?.avatar,
               let url = URL(string: avatarUrl) {

                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .clipShape(Circle())
                .frame(width: 48, height: 48)

            } else {
                Circle()
                    .fill(Color(red: 0x37/255, green: 0x41/255, blue: 0x51/255))
                    .overlay(
                        Text(initials)
                            .foregroundColor(GreenAccent)
                            .font(.system(size: 16, weight: .bold))
                    )
            }
        }
    }

    private var initials: String {
        guard let a = publication.author else { return "?" }
        let f = a.firstName.first.map(String.init) ?? ""
        let l = a.lastName.first.map(String.init) ?? ""
        return f + l == "" ? "?" : f + l
    }
}



// MARK: - Interaction Button
struct InteractionButtonView: View {
    let systemImage: String
    let label: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(label)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
        }
    }
}



// MARK: - States (inchangés)
struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(GreenAccent)
                .scaleEffect(1.5)
            Text("Loading publications...")
                .foregroundColor(TextSecondary)
                .font(.system(size: 14))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BackgroundDark.ignoresSafeArea())
    }
}

struct EmptyStateView: View {
    var onCreatePost: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("🚴")
                .font(.system(size: 64))
            Text("No publications yet")
                .foregroundColor(TextPrimary)
                .font(.system(size: 18, weight: .bold))
            Text("Be the first to share your cycling journey!")
                .foregroundColor(TextSecondary)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: onCreatePost) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Post")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(GreenAccent)
                .foregroundColor(.black)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BackgroundDark.ignoresSafeArea())
    }
}

struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("❌")
                .font(.system(size: 64))
            Text("Oops! Something went wrong")
                .foregroundColor(TextPrimary)
                .font(.system(size: 18, weight: .bold))
            Text(message)
                .foregroundColor(TextSecondary)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: onRetry) {
                Text("Retry")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(GreenAccent)
                    .foregroundColor(.black)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BackgroundDark.ignoresSafeArea())
    }
}



// MARK: - Helpers
private func formatNumber(_ count: Int) -> String {
    switch count {
    case 1_000_000...: return "\(count / 1_000_000)M"
    case 1_000...:     return "\(count / 1_000)K"
    default:           return "\(count)"
    }
}

private func formatTimestamp(_ timestamp: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)

    guard let date = formatter.date(from: timestamp) else { return "Recently" }

    let diff = Date().timeIntervalSince(date)
    let minutes = Int(diff / 60)
    let hours = minutes / 60
    let days = hours / 24

    if days > 30 { return "\(days / 30) months ago" }
    if days > 0  { return "\(days) days ago" }
    if hours > 0 { return "\(hours) hours ago" }
    if minutes > 0 { return "\(minutes) min ago" }
    return "Just now"
}
