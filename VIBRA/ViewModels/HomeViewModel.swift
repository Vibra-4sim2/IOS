// HomeViewModel.swift
// VIBRA

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var items: [RideWithCreator] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // 🔍 Recherche et filtres
    @Published var searchText: String = ""
    @Published var selectedTab: String = "Explore"        // "Followers", "Recommendation", "Explore"
    @Published var selectedActivity: String = "All"       // "All", "Randonnée", "Vélo"

    // 🔎 Liste filtrée utilisée par la vue
    var filteredItems: [RideWithCreator] {
        var result = items

        // 1) Filtre par activité (type de sortie)
        switch selectedActivity {
        case "Randonnée":
            result = result.filter { $0.ride.type?.uppercased().contains("RANDON") == true || $0.ride.type?.uppercased().contains("HIKE") == true }
        case "Vélo":
            result = result.filter { $0.ride.type?.uppercased().contains("VELO") == true || $0.ride.type?.uppercased().contains("CYCLE") == true }
        default:
            break
        }

        // 2) Filtre par onglet (Followers / Recommendation / Explore)
        switch selectedTab {
        case "Followers":
            // TODO: si tu as une logique backend de "follow", branche-la ici.
            // Pour l'instant on laisse tout, ou on appliquera plus tard un filtre spécifique.
            break
        case "Recommendation":
            // TODO: tu peux trier/filtrer par pertinence, popularité, etc.
            break
        case "Explore":
            break
        default:
            break
        }

        // 3) Filtre par texte (titre, description, nom de créateur)
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            let lower = text.lowercased()
            result = result.filter { item in
                let title = item.ride.titre.lowercased()
                let desc = item.ride.description?.lowercased() ?? ""
                let creatorName = "\(item.creator?.firstName ?? "") \(item.creator?.lastName ?? "")".lowercased()
                return title.contains(lower) || desc.contains(lower) || creatorName.contains(lower)
            }
        }

        return result
    }

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
