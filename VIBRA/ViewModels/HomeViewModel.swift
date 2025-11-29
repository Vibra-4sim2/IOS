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

    // 🆕 ID de l'utilisateur connecté
    private var currentUserId: String? {
        // D'abord essayer UserDefaults (plus rapide)
        if let userId = JWTHelper.getUserIdFromUserDefaults() {
            return userId
        }
        // Sinon, décoder depuis le JWT
        return JWTHelper.getUserIdFromToken()
    }

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

        // 2) Note: Le filtre par onglet (Followers / Recommendation / Explore)
        // est maintenant géré au niveau du chargement des données
        // On ne filtre plus ici, car les données sont déjà filtrées par la source

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

    // 🔄 Fonction principale de chargement (appelée quand l'onglet change)
    func load() async {
        switch selectedTab {
        case "Followers":
            await loadFollowersRides()
        case "Recommendation":
            await loadRecommendedRides()
        case "Explore":
            await loadAllRides()
        default:
            await loadAllRides()
        }
    }

    // 📋 Charger toutes les sorties (Explore)
    private func loadAllRides() async {
        print("🔄 HomeViewModel: Loading all rides (Explore)...")
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

    // ⭐ Charger les sorties recommandées
    private func loadRecommendedRides() async {
        print("⭐ HomeViewModel: Loading recommended rides...")
        
        guard let userId = currentUserId else {
            print("⚠️ HomeViewModel: No user ID found, cannot load recommendations")
            self.errorMessage = "Connectez-vous pour voir vos recommandations personnalisées"
            self.items = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await HomeService.shared.fetchRecommendedRidesWithCreators(userId: userId)
            print("✅ HomeViewModel: Successfully fetched \(fetched.count) recommended rides")
            self.items = fetched
        } catch APIError.invalidResponse(401) {
            print("❌ HomeViewModel: Authentication error (401)")
            self.errorMessage = "Session expirée. Veuillez vous reconnecter."
            self.items = []
        } catch {
            print("❌ HomeViewModel: Error loading recommended rides - \(error)")
            self.errorMessage = "Erreur de chargement des recommandations: \(error.localizedDescription)"
            self.items = []
        }
        isLoading = false
    }

    // 👥 Charger les sorties des personnes suivies
    private func loadFollowersRides() async {
        print("👥 HomeViewModel: Loading followers rides...")
        // TODO: Implémenter la logique pour charger les sorties des personnes suivies
        // Pour l'instant, on charge toutes les sorties
        // Vous devrez créer une route API dédiée pour cela
        await loadAllRides()
    }

    // 🔄 Recharger les données quand l'onglet change
    func onTabChange() async {
        await load()
    }
}
