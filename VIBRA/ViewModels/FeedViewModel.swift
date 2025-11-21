//
//  FeedViewModel.swift
//  VIBRA
//
//  Created by mac book pro on 11/17/25.
//
import Foundation
import Combine

/// États possibles du feed
enum FeedUiState {
    case loading
    case success
    case empty
    case error(message: String)
}

/// ViewModel pour gérer le feed des publications
@MainActor
final class FeedViewModel: ObservableObject {

    @Published var uiState: FeedUiState = .loading
    @Published var publications: [PublicationResponse] = []

    private let service = PublicationService.shared

    private let currentUserId: String? = UserDefaults.standard.string(forKey: "userId")

    init() {
        loadPublications()
    }

    /// Charger toutes les publications
    func loadPublications() {
        uiState = .loading

        Task {
            let result = await service.getAllPublications()
            switch result {
            case .success(let list):
                self.publications = list
                self.uiState = list.isEmpty ? .empty : .success
            case .failure(let error):
                self.uiState = .error(message: error.localizedDescription)
            }
        }
    }

    /// Rafraîchir le feed
    func refreshFeed() {
        loadPublications()
    }

    /// Liker/Unliker une publication
    func toggleLike(publicationId: String) {
        Task {
            let result = await service.likePublication(publicationId: publicationId)
            switch result {
            case .success(let updatedPublication):
                self.publications = self.publications.map { pub in
                    if pub.id == publicationId {
                        return PublicationResponse(
                            id: pub.id,
                            author: pub.author,
                            content: pub.content,
                            image: pub.image,
                            tags: pub.tags,
                            mentions: pub.mentions,
                            location: pub.location,
                            likesCount: updatedPublication.likesCount,
                            commentsCount: updatedPublication.commentsCount,
                            sharesCount: updatedPublication.sharesCount,
                            likedBy: updatedPublication.likedBy,
                            isActive: pub.isActive,
                            createdAt: pub.createdAt,
                            updatedAt: updatedPublication.updatedAt,
                            version: updatedPublication.version
                        )
                    }
                    return pub
                }
            case .failure:
                // Tu peux gérer une erreur (toast, log, etc.)
                break
            }
        }
    }

    /// Vérifier si l'utilisateur actuel a liké une publication
    func isLikedByCurrentUser(_ publication: PublicationResponse) -> Bool {
        guard let userId = currentUserId else { return false }
        return publication.likedBy?.contains(userId) == true
    }
}
