import Foundation
import Combine

@MainActor
final class MyRidesViewModel: ObservableObject {
    @Published var allItems: [RideWithCreator] = []
    @Published var myItems: [RideWithCreator] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUserId: String?

    /// participations en attente par sortieId (clé = id de Ride)
    @Published var pendingParticipationsByRideId: [String: [Participation]] = [:]

    @Published var searchText: String = "" {
        didSet {
            applyMyRidesFilter()
        }
    }

    /// Nombre total de participations en attente (pour badge global)
    var totalPendingCount: Int {
        pendingParticipationsByRideId.values.reduce(0) { $0 + $1.count }
    }

    init() {
        Task { await load() }
    }

    // MARK: - Chargement global (sorties + participations)
    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            try await loadCurrentUserIdFromJWT()
            let fetched = try await HomeService.shared.fetchRidesWithCreators()
            self.allItems = fetched
            applyMyRidesFilter()
            await loadPendingParticipationsForMyRides()
        } catch {
            self.errorMessage = "Erreur de chargement: \(error.localizedDescription)"
            self.allItems = []
            self.myItems = []
            self.pendingParticipationsByRideId = [:]
        }

        isLoading = false
    }

    /// Recharge uniquement les participations (ex: pull-to-refresh, badge)
    func reloadParticipations() async {
        await loadPendingParticipationsForMyRides()
    }

    // MARK: - JWT / User

    private func loadCurrentUserIdFromJWT() async throws {
        do {
            let token = try KeychainManager.shared.getJWT()
            if let userId = decodeUserId(fromJWT: token) {
                self.currentUserId = userId
            } else {
                self.currentUserId = nil
            }
        } catch {
            self.currentUserId = nil
        }
    }

    private func decodeUserId(fromJWT token: String) -> String? {
        let segments = token.split(separator: ".")
        guard segments.count >= 2 else { return nil }

        let payloadSegment = segments[1]

        var base64 = String(payloadSegment)
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        while base64.count % 4 != 0 {
            base64.append("=")
        }

        guard let payloadData = Data(base64Encoded: base64) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] else {
            return nil
        }

        if let id = json["id"] as? String { return id }
        if let userId = json["userId"] as? String { return userId }
        if let sub = json["sub"] as? String { return sub }
        if let mongoId = json["_id"] as? String { return mongoId }

        return nil
    }

    // MARK: - Filtres

    func applyMyRidesFilter() {
        guard let currentUserId = currentUserId else {
            myItems = []
            return
        }

        var result = allItems.filter { item in
            if let creatorId = item.ride.createurId {
                return creatorId == currentUserId
            }
            return false
        }

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

        self.myItems = result
    }

    // MARK: - Participations

    /// Charge les participations EN_ATTENTE pour chacune de mes sorties
    private func loadPendingParticipationsForMyRides() async {
        guard !myItems.isEmpty else {
            pendingParticipationsByRideId = [:]
            return
        }

        var tmpDict: [String: [Participation]] = [:]

        await withTaskGroup(of: (String, [Participation]).self) { group in
            for item in myItems {
                guard let rideId = item.ride.id else { continue }

                group.addTask {
                    do {
                        let participations = try await ParticipationService.shared.listParticipations(sortieId: rideId)
                        let pending = participations.filter { $0.status == "EN_ATTENTE" }
                        return (rideId, pending)
                    } catch {
                        print("❌ MyRidesViewModel: Failed to load participations for sortie \(rideId) - \(error)")
                        return (rideId, [])
                    }
                }
            }

            for await (rideId, pending) in group {
                tmpDict[rideId] = pending
            }
        }

        self.pendingParticipationsByRideId = tmpDict
        print("📊 pendingParticipationsByRideId:", pendingParticipationsByRideId.keys)
    }

    func pendingParticipations(for rideId: String?) -> [Participation] {
        guard let id = rideId else { return [] }
        return pendingParticipationsByRideId[id] ?? []
    }

    // MARK: - Actions sur les participations

    /// Accepter une participation EN_ATTENTE (status -> ACCEPTEE) puis recharger les pending
    func acceptParticipation(_ participation: Participation, forRideId rideId: String) async {
        guard let participationId = participation.id else {
            print("❌ acceptParticipation: participation sans id")
            return
        }

        do {
            _ = try await ParticipationService.shared.updateParticipationStatus(id: participationId, status: "ACCEPTEE")
            // Après MAJ, on recharge les participations en attente
            await loadPendingParticipationsForMyRides()
        } catch {
            print("❌ acceptParticipation error:", error)
        }
    }
}
