//
//  RatingPromptViewModel.swift
//  VIBRA
//

import Foundation
import SwiftUI
import Combine

@MainActor
class RatingPromptViewModel: ObservableObject {
    @Published var queue: [RatingEligibleSortie] = []
    @Published var currentIndex: Int = 0
    @Published var selectedStars: Int = 0
    @Published var comment: String = ""
    @Published var isPresenting: Bool = false
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?

    private var hasShownThisActivation: Bool = false

    var currentSortie: RatingEligibleSortie? {
        guard currentIndex >= 0 && currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }

    func onSceneBecameActive() {
        Task {
            await refreshEligibilityIfNeeded()
        }
    }

    func onSceneResignedActive() {
        hasShownThisActivation = false
    }

    func refreshEligibilityIfNeeded() async {
        if hasShownThisActivation {
            print("[RatingPrompt] Skipping refresh - already shown this activation")
            return
        }
        do {
            let all = try await RatingService.shared.getEligibleSortieRatings()
            print("[RatingPrompt] Fetched eligible sorties count:", all.count)
            let skipped = RatingPromptStorage.shared.loadSkippedIds()
            print("[RatingPrompt] Skipped IDs:", skipped)
            let filtered = all.filter { !skipped.contains($0.sortieId) }
            print("[RatingPrompt] Filtered eligible sorties count:", filtered.count)
            guard !filtered.isEmpty else {
                print("[RatingPrompt] No eligible sorties after filtering → no popup")
                return
            }
            self.queue = filtered
            self.currentIndex = 0
            self.selectedStars = 0
            self.comment = ""
            self.errorMessage = nil
            self.isPresenting = true
            self.hasShownThisActivation = true
            print("[RatingPrompt] Will present popup for sortie:", filtered.first?.title ?? "<none>")
        } catch {
            print("⚠️ Failed to load eligible sortie ratings:", error)
        }
    }

    func selectStars(_ value: Int) {
        selectedStars = max(1, min(5, value))
    }

    func submitCurrent() async {
        guard let current = currentSortie else { return }
        guard selectedStars > 0 else { return }
        isSubmitting = true
        errorMessage = nil
        let body = SubmitSortieRatingRequest(stars: selectedStars, comment: comment.isEmpty ? nil : comment)
        do {
            try await RatingService.shared.submitSortieRating(sortieId: current.sortieId, requestBody: body)
            advanceToNext()
        } catch {
            errorMessage = "Impossible d'envoyer la note. Veuillez réessayer ou passer."
            print("❌ submitCurrent error:", error)
        }
        isSubmitting = false
    }

    func skipCurrent() {
        guard let current = currentSortie else { return }
        RatingPromptStorage.shared.addSkippedId(current.sortieId)
        advanceToNext()
    }

    private func advanceToNext() {
        selectedStars = 0
        comment = ""
        currentIndex += 1
        if currentIndex >= queue.count {
            isPresenting = false
            queue = []
            currentIndex = 0
        }
    }

    func resetForNewUser() {
        queue = []
        currentIndex = 0
        selectedStars = 0
        comment = ""
        errorMessage = nil
        isPresenting = false
        hasShownThisActivation = false
    }
}
