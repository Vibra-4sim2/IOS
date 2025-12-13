//
//  MatchProfileViewModel.swift
//  VIBRA
//
//  ViewModel pour gérer le profil d'un match
//

import Foundation
import Combine

@MainActor
final class MatchProfileViewModel: ObservableObject {
    // MARK: - Inputs
    let userId: String

    // MARK: - Segments
    enum Segment {
        case mesSorties
        case creees
        case publications
    }

    @Published var selectedSegment: Segment = .mesSorties

    // MARK: - Published state
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Follow stats
    @Published var followersCount: Int = 0
    @Published var followingCount: Int = 0
    @Published var isFollowing: Bool = false
    @Published var isFollowLoading: Bool = false

    // Rating
    @Published var rating: UserRating?
    @Published var isLoadingRating = false

    // Content counts
    @Published var sortiesCount: Int = 0
    @Published var publicationsCount: Int = 0

    // Content lists
    @Published var rides: [RideWithCreator] = []
    @Published var createdRides: [RideWithCreator] = []
    @Published var publications: [PublicationResponse] = []

    init(userId: String) {
        self.userId = userId
    }

    // MARK: - Public API
    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetchedUser = try await AuthService.shared.getUser(byId: userId)
            self.user = fetchedUser

            // Parallel: follow stats, is-following, content lists, rating
            async let statsTask = AuthService.shared.fetchFollowStats(for: userId)
            async let isFollowingTask: Bool? = try? AuthService.shared.checkIsFollowing(userId: userId)
            async let ridesTask = HomeService.shared.fetchRidesWithCreators()
            async let publicationsTask = PublicationService.shared.getPublicationsByAuthor(authorId: userId)
            async let ratingTask = loadRating(for: userId)

            let stats = try await statsTask
            self.followersCount = stats.followersCount
            self.followingCount = stats.followingCount

            if let isFollow = await isFollowingTask {
                self.isFollowing = isFollow
            } else {
                self.isFollowing = false
            }

            let allRides = try await ridesTask
            let userRides = allRides.filter { $0.creator?.id == userId }
            self.rides = userRides
            self.createdRides = userRides
            self.sortiesCount = userRides.count

            let publicationsResult = await publicationsTask
            switch publicationsResult {
            case .success(let list):
                self.publications = list
                self.publicationsCount = list.count
            case .failure:
                self.publications = []
                self.publicationsCount = 0
            }

            // Wait for rating
            await ratingTask

            print("✅ MatchProfileViewModel: Profile loaded for user \(userId)")
        } catch {
            errorMessage = "Impossible de charger le profil. (\(error.localizedDescription))"
            print("❌ MatchProfileViewModel: Profile fetch error: \(error)")
        }
    }

    func toggleFollow() async {
        isFollowLoading = true
        defer { isFollowLoading = false }
        do {
            if isFollowing {
                try await AuthService.shared.unfollowUser(userId: userId)
                isFollowing = false
                followersCount = max(0, followersCount - 1)
            } else {
                try await AuthService.shared.followUser(userId: userId)
                isFollowing = true
                followersCount += 1
            }
        } catch {
            print("❌ MatchProfileViewModel: toggleFollow error: \(error)")
        }
    }

    // MARK: - Rating
    private func loadRating(for userId: String) async {
        isLoadingRating = true
        defer { isLoadingRating = false }
        do {
            let fetchedRating = try await RatingService.shared.refreshAndGetCreatorRating(userId: userId)
            self.rating = fetchedRating
            print("✅ MatchProfileViewModel: Rating loaded: \(fetchedRating.average) stars (\(fetchedRating.count) reviews)")
        } catch {
            print("⚠️ MatchProfileViewModel: Could not load rating for user \(userId): \(error)")
            self.rating = nil
        }
    }
}
