// HomeViewModel.swift
// VIBRA

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var items: [RideWithCreator] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        print("🔄 HomeViewModel: Starting to load rides...")
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await HomeService.shared.fetchRidesWithCreators()
            print("✅ HomeViewModel: Successfully fetched \(fetched.count) rides")
            self.items = fetched
        } catch {
            print("❌ HomeViewModel: Error loading rides - \(error)")
            self.errorMessage = "Erreur de chargement: \(error.localizedDescription)"
            self.items = []
        }
        isLoading = false
    }
}
