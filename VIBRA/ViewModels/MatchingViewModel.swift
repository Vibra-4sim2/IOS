//
//  MatchingViewModel.swift
//  VIBRA
//
//  ViewModel pour gérer le matching
//

import Foundation
import SwiftUI
import Combine
@MainActor
final class MatchingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var matches: [UserMatch] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var totalMatches = 0
    @Published var algorithm = ""
    
    // MARK: - Private Properties
    private let aiService = AIService.shared
    private var loadTask: Task<Void, Never>?
    
    // MARK: - Deinit
    deinit {
        loadTask?.cancel()
    }
    
    // MARK: - Public Methods
    func loadMatches() async {
        // Annuler toute tâche précédente
        loadTask?.cancel()
        
        // Créer une nouvelle tâche
        loadTask = Task {
            isLoading = true
            errorMessage = nil
            
            do {
                // Vérifier si la tâche est annulée
                try Task.checkCancellation()
                
                print("🔄 MatchingViewModel: Loading matches...")
                let response = try await aiService.getMatches()
                
                // Vérifier à nouveau après l'appel réseau
                try Task.checkCancellation()
                
                self.matches = response.matches
                self.totalMatches = response.totalMatches
                self.algorithm = response.algorithm
                print("✅ MatchingViewModel: Loaded \(response.totalMatches) matches")
            } catch is CancellationError {
                print("⚠️ MatchingViewModel: Task was cancelled")
            } catch let error as AIService.AIServiceError {
                self.errorMessage = error.errorDescription
                print("❌ MatchingViewModel: Error - \(error.errorDescription ?? "Unknown")")
            } catch {
                // Ignorer les erreurs d'annulation réseau
                if (error as NSError).code != NSURLErrorCancelled {
                    self.errorMessage = "Une erreur inattendue s'est produite"
                    print("❌ MatchingViewModel: Unexpected error - \(error)")
                } else {
                    print("⚠️ MatchingViewModel: Network request was cancelled")
                }
            }
            
            isLoading = false
        }
        
        await loadTask?.value
    }
    
    func refreshMatches() async {
        await loadMatches()
    }
    
    func cancelLoading() {
        loadTask?.cancel()
        isLoading = false
    }
    
    // MARK: - Helper Methods
    func getMatchQualityColor(similarity: Double) -> Color {
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
    
    func getMatchQualityText(similarity: Double) -> String {
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
    
    func getMatchingPreferencesCount(preferences: MatchedPreferences) -> Int {
        var count = 0
        
        if preferences.level?.match == true { count += 1 }
        if preferences.cyclingType?.match == true { count += 1 }
        if preferences.cyclingFrequency?.match == true { count += 1 }
        if preferences.hikeType?.match == true { count += 1 }
        if preferences.hikeDuration?.match == true { count += 1 }
        if preferences.hikePreference?.match == true { count += 1 }
        if preferences.campingPractice?.match == true { count += 1 }
        if preferences.campingType?.match == true { count += 1 }
        
        return count
    }
}
