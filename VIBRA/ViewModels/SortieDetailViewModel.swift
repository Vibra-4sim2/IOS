// filepath: /Users/mohamedmami/Documents/IOS/VIBRA/ViewModels/SortieDetailViewModel.swift
import Foundation
import CoreLocation
import MapKit
import Combine

@MainActor
final class SortieDetailViewModel: ObservableObject {
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var routeDistanceMeters: Double?
    // Participants state
    @Published var participants: [User] = []
    @Published var participantIds: [String] = []
    @Published var isParticipating = false
    @Published var participationMessage: String?

    let ride: Ride
    let creator: User?

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

    init(ride: Ride, creator: User?) {
        self.ride = ride
        self.creator = creator
        // Initialize participants from ride payload if present
        if let users = ride.participants { self.participants = users }
        if let ids = ride.participantIds { self.participantIds = ids }
    }

    func loadRoute(profileOverride: String? = nil) async {
        errorMessage = nil
        routeCoordinates = []
        guard let start = startCoordinate, let end = endCoordinate else { return }
        isLoading = true
        defer { isLoading = false }

        let profile = profileOverride ?? profileFromType(ride.type)
        do {
            let (coords, distance) = try await RouteFetcher.fetchRouteCoordinates(from: start, to: end, profile: profile)
            routeCoordinates = coords
            routeDistanceMeters = distance
        } catch {
            errorMessage = "Échec du tracé de l'itinéraire: \(error)"
        }
    }

    private func profileFromType(_ type: String?) -> String {
        guard let t = type?.uppercased() else { return "foot-walking" }
        switch t {
            case "VELO", "VÉLO", "CYCLING": return "cycling-regular"
            case "CAMPING", "RANDONNEE", "RANDONNÉE", "HIKING": return "foot-walking"
            default: return "foot-walking"
        }
    }

    // MARK: - Participation
    private func currentUserId() -> String? {
        guard let token = try? KeychainManager.shared.getJWT() else { return nil }
        return token.getUserIdFromJWT()
    }

    var alreadyParticipating: Bool {
        guard let uid = currentUserId() else { return false }
        if participants.contains(where: { $0.id == uid }) { return true }
        if participantIds.contains(where: { $0 == uid }) { return true }
        return false
    }

    func participate() async {
        guard let sortieId = ride.id else { participationMessage = "Sortie inconnue"; return }
        guard let uid = currentUserId() else { participationMessage = "Veuillez vous reconnecter"; return }
        if alreadyParticipating { participationMessage = "Vous participez déjà"; return }

        isParticipating = true
        participationMessage = nil
        defer { isParticipating = false }
        do {
            _ = try await ParticipationService.shared.createParticipation(userId: uid, sortieId: sortieId)
            // Update local state: append id and fetch user for richer display
            if !participantIds.contains(uid) { participantIds.append(uid) }
            let user = try await AuthService.shared.getUser(byId: uid)
            if !participants.contains(where: { $0.id == user.id }) {
                participants.append(user)
            }
            participationMessage = "Participation enregistrée"
        } catch {
            participationMessage = "Échec de la participation: \(error.localizedDescription)"
        }
    }
}
