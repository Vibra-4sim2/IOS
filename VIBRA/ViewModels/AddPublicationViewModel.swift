//
//  AddPublicationViewModel.swift
//  VIBRA
//
//  Created by mac book pro on 11/21/25.
//
import Foundation
import SwiftUI
import Combine

/// États possibles de l'UI d'ajout de publication
enum AddPublicationUiState {
    case idle
    case loading
    case success(publicationId: String)
    case error(message: String)
}

@MainActor
final class AddPublicationViewModel: ObservableObject {

    // Etat UI
    @Published var uiState: AddPublicationUiState = .idle

    // Champs du formulaire
    @Published var content: String = ""
    @Published var selectedTags: [String] = []
    @Published var mentionedUsers: [String] = []
    @Published var location: String = ""
    @Published var selectedImage: UIImage? = nil

    private let service = PublicationService.shared

    // MARK: - Mise à jour des champs

    func updateContent(_ newContent: String) {
        content = newContent
    }

    func addTag(_ tag: String) {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !selectedTags.contains(trimmed) else { return }
        selectedTags.append(trimmed)
    }

    func removeTag(_ tag: String) {
        selectedTags.removeAll { $0 == tag }
    }

    func setTags(_ tags: [String]) {
        selectedTags = tags
    }

    func addMention(_ userId: String) {
        let trimmed = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !mentionedUsers.contains(trimmed) else { return }
        mentionedUsers.append(trimmed)
    }

    func removeMention(_ userId: String) {
        mentionedUsers.removeAll { $0 == userId }
    }

    func setMentions(_ userIds: [String]) {
        mentionedUsers = userIds
    }

    func updateLocation(_ newLocation: String) {
        location = newLocation
    }

    func selectImage(_ image: UIImage?) {
        selectedImage = image
    }

    // MARK: - Publication

    func publishPublication() {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            uiState = .error(message: "Le contenu ne peut pas être vide")
            return
        }

        uiState = .loading

        Task {
            let result = await service.createPublication(
                content: trimmed,
                image: selectedImage,
                tags: selectedTags.isEmpty ? nil : selectedTags,
                mentions: mentionedUsers.isEmpty ? nil : mentionedUsers,
                location: location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : location
            )

            switch result {
            case .success(let publication):
                uiState = .success(publicationId: publication.id)
                resetForm()
            case .failure(let error):
                uiState = .error(message: error.localizedDescription)
            }
        }
    }

    func resetForm() {
        content = ""
        selectedTags = []
        mentionedUsers = []
        location = ""
        selectedImage = nil
    }

    func resetUiState() {
        uiState = .idle
    }
}
