// MapViewModel.swift
// VIBRA

import Foundation
import Combine
import CoreLocation
import MapKit

@MainActor
final class MapViewModel: ObservableObject {
    @Published var items: [RideWithCreator] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedRide: RideWithCreator?
    
    @Published var searchText: String = ""
    @Published var selectedTab: String = "Explore"
    @Published var selectedActivity: String = "All"
    @Published var selectedDateFilter: DateFilter = .all
    
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 36.8065, longitude: 10.1815),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    
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
        
        return result.filter { $0.ride.pointDepart != nil }
    }
    
    var mapAnnotations: [RideAnnotation] {
        filteredItems.compactMap { item in
            guard let point = item.ride.pointDepart else { return nil }
            return RideAnnotation(
                id: item.ride.id ?? UUID().uuidString,
                coordinate: CLLocationCoordinate2D(
                    latitude: point.latitude,
                    longitude: point.longitude
                ),
                title: item.ride.titre,
                date: item.ride.date,
                type: item.ride.type,
                rideWithCreator: item
            )
        }
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
        print("📄 MapViewModel: Loading all rides...")
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await HomeService.shared.fetchRidesWithCreators()
            print("✅ MapViewModel: Successfully fetched \(fetched.count) rides")
            self.items = fetched
            updateMapRegion()
        } catch {
            print("❌ MapViewModel: Error loading rides - \(error)")
            self.errorMessage = "Erreur de chargement: \(error.localizedDescription)"
            self.items = []
        }
        isLoading = false
    }
    
    private func loadRecommendedRides() async {
        print("⭐ MapViewModel: Loading recommended rides...")
        
        guard let userId = currentUserId else {
            print("⚠️ MapViewModel: No user ID found")
            self.errorMessage = "Connectez-vous pour voir vos recommandations"
            self.items = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await HomeService.shared.fetchRecommendedRidesWithCreators(userId: userId)
            print("✅ MapViewModel: Successfully fetched \(fetched.count) recommended rides")
            self.items = fetched
            updateMapRegion()
        } catch APIError.invalidResponse(401) {
            print("❌ MapViewModel: Authentication error")
            self.errorMessage = "Session expirée"
            self.items = []
        } catch {
            print("❌ MapViewModel: Error loading recommended rides - \(error)")
            self.errorMessage = "Erreur de chargement: \(error.localizedDescription)"
            self.items = []
        }
        isLoading = false
    }
    
    private func loadFollowersRides() async {
        print("👥 MapViewModel: Loading followers rides...")
        await loadAllRides()
    }
    
    func onTabChange() async {
        await load()
    }
    
    func resetFilters() {
        searchText = ""
        selectedActivity = "All"
        selectedDateFilter = .all
    }
    
    var activeFiltersCount: Int {
        var count = 0
        if !searchText.isEmpty { count += 1 }
        if selectedActivity != "All" { count += 1 }
        if selectedDateFilter != .all { count += 1 }
        return count
    }
    
    func updateMapRegion() {
        guard !filteredItems.isEmpty else { return }
        
        let coordinates = filteredItems.compactMap { $0.ride.pointDepart }
        guard !coordinates.isEmpty else { return }
        
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 36.8065
        let maxLat = latitudes.max() ?? 36.8065
        let minLon = longitudes.min() ?? 10.1815
        let maxLon = longitudes.max() ?? 10.1815
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        let spanLat = max((maxLat - minLat) * 1.5, 0.1)
        let spanLon = max((maxLon - minLon) * 1.5, 0.1)
        
        mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
        )
    }
    
    func centerOnUserLocation(_ location: CLLocationCoordinate2D) {
        mapRegion = MKCoordinateRegion(
            center: location,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    }
}

struct RideAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let title: String
    let date: String?
    let type: String?
    let rideWithCreator: RideWithCreator
}
