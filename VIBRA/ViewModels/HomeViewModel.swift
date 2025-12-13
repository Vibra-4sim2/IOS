// HomeViewModel.swift
// VIBRA

import Foundation
import Combine
import CoreLocation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var items: [RideWithCreator] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var searchText: String = ""
    @Published var selectedTab: String = "Explore"
    @Published var selectedActivity: String = "All"
    
    @Published var selectedDateFilter: DateFilter = .all
    @Published var selectedLocation: String = ""
    @Published var searchRadius: Double = 50
    @Published var userLocation: CLLocationCoordinate2D?
    
    @Published var isRecording = false
    
    private var currentUserId: String? {
        if let userId = JWTHelper.getUserIdFromUserDefaults() {
            return userId
        }
        return JWTHelper.getUserIdFromToken()
    }
    
    enum DateFilter: String, CaseIterable {
        case all = "Toutes"
        case today = "Aujourd'hui"
        case thisWeek = "Cette semaine"
        case thisMonth = "Ce mois"
        case upcoming = "À venir"
        
        var icon: String {
            switch self {
            case .all: return "calendar"
            case .today: return "calendar.badge.clock"
            case .thisWeek: return "calendar.badge.plus"
            case .thisMonth: return "calendar.circle"
            case .upcoming: return "arrow.right.circle"
            }
        }
    }

    var filteredItems: [RideWithCreator] {
        var result = items

        switch selectedActivity {
        case "Randonnée":
            result = result.filter { $0.ride.type?.uppercased().contains("RANDON") == true || $0.ride.type?.uppercased().contains("HIKE") == true }
        case "Vélo":
            result = result.filter { $0.ride.type?.uppercased().contains("VELO") == true || $0.ride.type?.uppercased().contains("CYCLE") == true || $0.ride.type?.uppercased().contains("BIKE") == true }
        default:
            break
        }

        result = filterByDate(result)
        
        if !selectedLocation.isEmpty || userLocation != nil {
            result = filterByLocation(result)
        }

        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            let lower = text.lowercased()
            result = result.filter { item in
                let title = item.ride.titre.lowercased()
                let desc = item.ride.description?.lowercased() ?? ""
                let creatorName = "\(item.creator?.firstName ?? "") \(item.creator?.lastName ?? "")".lowercased()
                let type = item.ride.type?.lowercased() ?? ""
                return title.contains(lower) || desc.contains(lower) || creatorName.contains(lower) || type.contains(lower)
            }
        }

        return result
    }
    
    private func filterByDate(_ items: [RideWithCreator]) -> [RideWithCreator] {
        guard selectedDateFilter != .all else { return items }
        
        let calendar = Calendar.current
        let now = Date()
        
        return items.filter { item in
            guard let dateString = item.ride.date,
                  let rideDate = parseDate(dateString) else {
                return false
            }
            
            switch selectedDateFilter {
            case .all:
                return true
            case .today:
                return calendar.isDateInToday(rideDate)
            case .thisWeek:
                guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
                      let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
                    return false
                }
                return rideDate >= weekStart && rideDate < weekEnd
            case .thisMonth:
                return calendar.isDate(rideDate, equalTo: now, toGranularity: .month)
            case .upcoming:
                return rideDate >= now
            }
        }
    }
    
    private func filterByLocation(_ items: [RideWithCreator]) -> [RideWithCreator] {
        guard let userLoc = userLocation else { return items }
        
        return items.filter { item in
            guard let startPoint = item.ride.pointDepart else { return true }
            
            let rideLocation = CLLocation(
                latitude: startPoint.latitude,
                longitude: startPoint.longitude
            )
            let userCLLocation = CLLocation(
                latitude: userLoc.latitude,
                longitude: userLoc.longitude
            )
            
            let distance = userCLLocation.distance(from: rideLocation) / 1000
            return distance <= searchRadius
        }
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd",
            "dd/MM/yyyy"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "fr_FR")
            formatter.timeZone = TimeZone.current
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }

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

    private func loadAllRides() async {
        print("📄 HomeViewModel: Loading all rides (Explore)...")
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

    private func loadFollowersRides() async {
        print("👥 HomeViewModel: Loading followers rides...")
        await loadAllRides()
    }

    func onTabChange() async {
        await load()
    }
    
    func resetFilters() {
        searchText = ""
        selectedActivity = "All"
        selectedDateFilter = .all
        selectedLocation = ""
        searchRadius = 50
    }
    
    var activeFiltersCount: Int {
        var count = 0
        if !searchText.isEmpty { count += 1 }
        if selectedActivity != "All" { count += 1 }
        if selectedDateFilter != .all { count += 1 }
        if !selectedLocation.isEmpty || userLocation != nil { count += 1 }
        return count
    }
}
