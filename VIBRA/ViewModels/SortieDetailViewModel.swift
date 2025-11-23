// filepath: /Users/mohamedmami/Documents/IOS/VIBRA/ViewModels/SortieDetailViewModel.swift
import Foundation
import CoreLocation
import MapKit
import Combine

// MARK: - Weather DTO

struct DailyWeather: Decodable {
    let time: [String]
    let weathercode: [Int]
    let temperature_2m_max: [Double]
    let temperature_2m_min: [Double]
    let windspeed_10m_max: [Double]
}

struct DailyUnits: Decodable {
    let temperature_2m_max: String?
    let windspeed_10m_max: String?
}

struct WeatherResponse: Decodable {
    let daily: DailyWeather?
    let daily_units: DailyUnits?
}

@MainActor
final class SortieDetailViewModel: ObservableObject {
    // Route state
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var routeDistanceMeters: Double?

    // Participants state (affichage des membres)
    @Published var participants: [User] = []
    @Published var participantIds: [String] = []

    // Participations brutes (EN_ATTENTE / ACCEPTEE / REFUSEE…)
    @Published var participations: [Participation] = []

    @Published var isParticipating = false
    @Published var participationMessage: String?

    // Weather state
    @Published var isLoadingWeather = false
    @Published var weatherErrorMessage: String?
    @Published var weatherSummary: String?
    @Published var weatherTemperatureText: String?
    @Published var weatherWindText: String?
    @Published private(set) var weatherIconName: String = "cloud"

    let ride: Ride
    let creator: User?

    // MARK: - Init

    init(ride: Ride, creator: User?) {
        self.ride = ride
        self.creator = creator
        // Initialise depuis la sortie si déjà fournie
        if let users = ride.participants { self.participants = users }
        if let ids = ride.participantIds { self.participantIds = ids }
    }

    // MARK: - Helpers

    var creatorFullName: String {
        if let c = creator { return "\(c.firstName) \(c.lastName)".trimmingCharacters(in: .whitespaces) }
        return "Utilisateur inconnu"
    }

    var dateOnly: String {
        guard let ds = ride.date else { return "" }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: ds) {
            let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR"); f.dateFormat = "dd MMM yyyy"
            return f.string(from: d)
        }
        return ds
    }

    var timeOnly: String {
        guard let ds = ride.date else { return "" }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: ds) {
            let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR"); f.dateFormat = "HH:mm"
            return f.string(from: d)
        }
        return ""
    }

    var startCoordinate: CLLocationCoordinate2D? {
        if let p = ride.pointDepart { return CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude) }
        return nil
    }

    var endCoordinate: CLLocationCoordinate2D? {
        if let p = ride.pointArrivee { return CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude) }
        return nil
    }

    // MARK: - Route

    func loadRoute(profileOverride: String? = nil) async {
        errorMessage = nil
        routeCoordinates = []
        guard let start = startCoordinate, let end = endCoordinate else { return }
        isLoading = true
        defer { isLoading = false }

        let profile = profileFromType(ride.type)
        do {
            let (coords, distance) = try await RouteFetcher.fetchRouteCoordinates(
                from: start,
                to: end,
                profile: profileOverride ?? profile
            )
            routeCoordinates = coords
            routeDistanceMeters = distance
        } catch {
            errorMessage = "Échec du tracé de l'itinéraire: \(error)"
        }
    }

    private func profileFromType(_ type: String?) -> String {
        guard let t = type?.uppercased() else { return "foot-walking" }
        switch t {
        case "VELO", "VÉLO", "CYCLING":
            return "cycling-regular"
        case "CAMPING", "RANDONNEE", "RANDONNÉE", "HIKING":
            return "foot-walking"
        default:
            return "foot-walking"
        }
    }

    // MARK: - Weather

    var weatherAvailable: Bool {
        weatherSummary != nil || weatherTemperatureText != nil || weatherWindText != nil
    }

    func loadWeather() async {
        weatherErrorMessage = nil
        weatherSummary = nil
        weatherTemperatureText = nil
        weatherWindText = nil

        guard let start = startCoordinate else { return }
        guard let dateString = ride.date else { return }

        guard let dateOnlyString = Self.isoStringToDateOnly(dateString) else {
            weatherErrorMessage = "Date invalide pour la météo"
            return
        }

        isLoadingWeather = true
        defer { isLoadingWeather = false }

        do {
            let response = try await fetchWeather(
                latitude: start.latitude,
                longitude: start.longitude,
                date: dateOnlyString
            )

            guard let daily = response.daily,
                  let firstDate = daily.time.first,
                  firstDate == dateOnlyString
            else {
                weatherErrorMessage = "Aucune donnée météo pour cette date"
                return
            }

            let code = daily.weathercode.first ?? 0
            let tMax = daily.temperature_2m_max.first
            let tMin = daily.temperature_2m_min.first
            let wind = daily.windspeed_10m_max.first
            let tempUnit = response.daily_units?.temperature_2m_max ?? "°C"
            let windUnit = response.daily_units?.windspeed_10m_max ?? "km/h"

            weatherIconName = iconName(for: code)
            weatherSummary = description(for: code)

            if let tMax = tMax, let tMin = tMin {
                weatherTemperatureText = String(format: "Température: %.0f / %.0f %@", tMin, tMax, tempUnit)
            } else if let tMax = tMax {
                weatherTemperatureText = String(format: "Température max: %.0f %@", tMax, tempUnit)
            }

            if let wind = wind {
                weatherWindText = String(format: "Vent max: %.0f %@", wind, windUnit)
            }
        } catch {
            weatherErrorMessage = "Impossible de charger la météo"
        }
    }

    private func fetchWeather(latitude: Double, longitude: Double, date: String) async throws -> WeatherResponse {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "daily", value: "weathercode,temperature_2m_max,temperature_2m_min,windspeed_10m_max"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "start_date", value: date),
            URLQueryItem(name: "end_date", value: date)
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(WeatherResponse.self, from: data)
    }

    private static func isoStringToDateOnly(_ iso: String) -> String? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso) else { return nil }
        let out = DateFormatter()
        out.locale = Locale(identifier: "en_US_POSIX")
        out.dateFormat = "yyyy-MM-dd"
        return out.string(from: date)
    }

    private func iconName(for weatherCode: Int) -> String {
        switch weatherCode {
        case 0: return "sun.max.fill"
        case 1, 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55, 56, 57: return "cloud.drizzle.fill"
        case 61, 63, 65, 80, 81, 82: return "cloud.rain.fill"
        case 71, 73, 75, 77, 85, 86: return "cloud.snow.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        default: return "cloud"
        }
    }

    private func description(for weatherCode: Int) -> String {
        switch weatherCode {
        case 0: return "Ciel dégagé"
        case 1: return "Principalement dégagé"
        case 2: return "Partiellement nuageux"
        case 3: return "Couvert"
        case 45, 48: return "Brouillard"
        case 51, 53, 55: return "Bruine"
        case 56, 57: return "Bruine verglaçante"
        case 61: return "Pluie faible"
        case 63: return "Pluie modérée"
        case 65: return "Pluie forte"
        case 71: return "Chute de neige faible"
        case 73: return "Chute de neige modérée"
        case 75: return "Chute de neige forte"
        case 77: return "Grains de neige"
        case 80: return "Averses faibles"
        case 81: return "Averses modérées"
        case 82: return "Fortes averses"
        case 85: return "Averses de neige faibles"
        case 86: return "Averses de neige fortes"
        case 95: return "Orages"
        case 96, 99: return "Orages avec grêle"
        default: return "Conditions inconnues"
        }
    }

    // MARK: - Participation

    private func currentUserId() -> String? {
        guard let token = try? KeychainManager.shared.getJWT() else { return nil }
        return token.getUserIdFromJWT()
    }

    /// Vrai si une participation existe déjà pour (sortieId, userId) dans `participations`
    var alreadyParticipating: Bool {
        guard let uid = currentUserId(), let sortieId = ride.id else { return false }

        // check sur les participations renvoyées par l'API
        if participations.contains(where: { $0.user?.id == uid && $0.sortie?.id == sortieId }) {
            return true
        }
        // fallback sur les anciens champs du ride (si déjà peuplés)
        if participants.contains(where: { $0.id == uid }) { return true }
        if participantIds.contains(where: { $0 == uid }) { return true }
        return false
    }

    /// Charge les participations pour cette sortie, et ne garde que les ACCEPTÉE dans les membres
    func loadParticipations() async {
        guard let sortieId = ride.id else { return }
        do {
            let list = try await ParticipationService.shared.listParticipations(sortieId: sortieId)
            self.participations = list

            // Garder uniquement les participations ACCEPTÉE pour la liste des membres
            let accepted = list.filter { $0.status == "ACCEPTEE" }
            self.participantIds = accepted.compactMap { $0.user?.id }

            // Charger les User complets pour affichage
            var users: [User] = []
            for uid in self.participantIds {
                do {
                    let u = try await AuthService.shared.getUser(byId: uid)
                    users.append(u)
                } catch {
                    print("❌ SortieDetailViewModel.loadParticipations: impossible de charger le user \(uid): \(error)")
                }
            }
            self.participants = users

            print("✅ loadParticipations: \(list.count) participations, \(accepted.count) ACCEPTÉE")
        } catch {
            print("❌ loadParticipations error:", error)
        }
    }

    func participate() async {
        guard let sortieId = ride.id else {
            participationMessage = "Sortie inconnue"
            return
        }
        guard let uid = currentUserId() else {
            participationMessage = "Veuillez vous reconnecter"
            return
        }
        if alreadyParticipating {
            participationMessage = "Vous participez déjà"
            return
        }

        isParticipating = true
        participationMessage = nil
        defer { isParticipating = false }

        do {
            print("🟢 participate(): création de participation pour user=\(uid) sortie=\(sortieId)")
            let created = try await ParticipationService.shared.createParticipation(userId: uid, sortieId: sortieId)
            print("✅ participate(): participation créée avec id=\(created.id ?? "<nil>") status=\(created.status ?? "<nil>")")

            // Succès garanti côté backend -> on met directement le message positif
            participationMessage = "Participation enregistrée"

            // Recharge en arrière-plan sans casser le message si ça plante
            Task {
                await self.loadParticipations()
            }
        } catch {
            print("❌ participate() error:", error)
            participationMessage = "Échec de la participation: \(error.localizedDescription)"
        }
    }
}
