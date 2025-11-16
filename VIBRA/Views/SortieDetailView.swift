// filepath: /Users/mohamedmami/Documents/IOS/VIBRA/Views/SortieDetailView.swift
import SwiftUI
import CoreLocation

struct SortieDetailView: View {
    @StateObject private var vm: SortieDetailViewModel
    private var isPreview: Bool { ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" }
    @Environment(\.dismiss) private var dismiss

    init(ride: Ride, creator: User?) {
        _vm = StateObject(wrappedValue: SortieDetailViewModel(ride: ride, creator: creator))
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 16) {
                    heroHeader
                    detailsCard
                    // Description and Itinerary grouped with no vertical spacing between them
                    VStack(spacing: 0) {
                        descriptionSection
                        mapSection
                    }
                    infoChips
                    participateButton
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .task {
            if !isPreview { await vm.loadRoute() }
        }
    }

    // MARK: - Hero Header (Image + Overlay)
    private var heroHeader: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if let urlStr = vm.ride.photo, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle().fill(Color.gray.opacity(0.3))
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            Rectangle().fill(Color.gray.opacity(0.3))
                        @unknown default:
                            Rectangle().fill(Color.gray.opacity(0.3))
                        }
                    }
                } else {
                    Rectangle().fill(Color.gray.opacity(0.3))
                }
            }
            .frame(height: 240)
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [Color.black.opacity(0.5), Color.clear, Color.black.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Back button only to keep image clean
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }
            .padding(.leading)
            .padding(.top, 12)
        }
        .cornerRadius(14)
        .padding(.horizontal)
    }

    // New: Details card below the image
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(vm.ride.titre)
                .font(.title3).bold()
                .foregroundColor(.white)
                .lineLimit(2)

            HStack(spacing: 12) {
                creatorAvatar
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.creatorFullName)
                        .foregroundColor(.white)
                        .font(.subheadline)
                    Text("Organisateur")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.caption)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.08))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private var creatorAvatar: some View {
        Group {
            if let urlStr = vm.creator?.avatar, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty: Circle().fill(Color.gray.opacity(0.3))
                    case .success(let img): img.resizable().scaledToFill()
                    case .failure: Circle().fill(Color.gray.opacity(0.3))
                    @unknown default: Circle().fill(Color.gray.opacity(0.3))
                    }
                }
            } else {
                Circle().fill(Color.gray.opacity(0.3))
                    .overlay(Image(systemName: "person.fill").foregroundColor(.white))
            }
        }
        .frame(width: 42, height: 42)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    // MARK: - Info Chips (date, time, distance, difficulty, capacity)
    private var infoChips: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Line 1
            HStack(spacing: 10) {
                chip(icon: "calendar", text: vm.dateOnly)
                chip(icon: "clock", text: vm.timeOnly)
                if let dist = vm.ride.distance { chip(icon: "ruler", text: distanceText(dist)) }
                if let diff = vm.ride.difficulte, !diff.isEmpty { chip(icon: "gauge", text: diff.capitalized) }
                Spacer()
            }
            // Line 2 (participants/capacity + camping)
            let pCount = max(vm.participants.count, vm.participantIds.count)
            let cap = vm.ride.capacite
            let hasCamping = includesCamping(vm.ride)
            if pCount > 0 || cap != nil || hasCamping {
                HStack(spacing: 10) {
                    // Participants indicator: current/max if cap available
                    if pCount > 0 || cap != nil {
                        let label = cap != nil ? "\(pCount) / \(cap!)" : "\(pCount)"
                        chip(icon: "person.2", text: label)
                    }
                    if hasCamping { chip(icon: "tent.fill", text: "Camping") }
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
    }

    private func includesCamping(_ ride: Ride) -> Bool {
        if let flag = ride.optionCamping, flag { return true }
        if ride.campingId != nil { return true }
        if ride.camping != nil { return true }
        return false
    }

    private func chip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption).foregroundColor(.green)
            Text(text).font(.caption).foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.7))
        .cornerRadius(10)
    }

    // MARK: - Map Section (like ChallengeDetail)
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Itinéraire")
                .foregroundColor(.white)
                .font(.headline)
                .padding(.horizontal)
            let start = vm.startCoordinate
            let end = vm.endCoordinate
            if let s = start, let e = end {
                RouteMapView(routeCoordinates: vm.routeCoordinates, startCoordinate: s, endCoordinate: e)
                    .frame(height: 300)
                    .cornerRadius(12)
                    .overlay(
                        Group {
                            if vm.isLoading { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) }
                        }
                        .padding(), alignment: .center
                    )
                    .padding(.horizontal)
            } else if let s = start ?? end { // show single point if only one is available
                SinglePointMap(center: s)
                    .frame(height: 300)
                    .cornerRadius(12)
                    .padding(.horizontal)
            } else {
                Text("Points de départ/arrivée non disponibles")
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal)
            }
        }
    }

    // New: Participate button at the bottom
    private var participateButton: some View {
        VStack(spacing: 8) {
            Button(action: { Task { await vm.participate() } }) {
                ZStack {
                    if vm.isParticipating {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(vm.alreadyParticipating ? "Déjà inscrit" : "Participer")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(vm.alreadyParticipating ? Color.gray.opacity(0.6) : Color.green.opacity(0.85))
                .cornerRadius(14)
            }
            .disabled(vm.isParticipating || vm.alreadyParticipating)
            if let msg = vm.participationMessage {
                Text(msg)
                    .font(.footnote)
                    .foregroundColor(msg.lowercased().contains("échec") ? .red : .green)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal)
    }

    private var descriptionSection: some View {
        Group {
            if let d = vm.ride.description, !d.isEmpty {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Description")
                        .foregroundColor(.white)
                        .font(.headline)
                    Text(d)
                        .foregroundColor(.white.opacity(0.9))
                        .font(.subheadline)
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Utilities
    private func distanceText(_ meters: Int) -> String {
        if meters >= 1000 { return String(format: "%.1f km", Double(meters) / 1000.0) }
        return "\(meters) m"
    }
}

// MARK: - Preview
#Preview {
    let data = """
    {
      "_id": "preview1",
      "titre": "Balade test",
      "description": "Aperçu de la sortie",
      "date": "2024-06-15T09:00:00.000Z",
      "type": "VELO",
      "option_camping": false,
      "createurId": "creator1",
      "photo": "https://picsum.photos/800/400",
      "capacite": 12,
      "distance": 12500,
      "duree_estimee": 18000,
      "pointDepart": { "latitude": 45.8326, "longitude": 6.8652 },
      "pointArrivee": { "latitude": 45.9237, "longitude": 6.8694 },
      "difficulte": "moyen"
    }
    """.data(using: .utf8)!
    let ride = try! JSONDecoder().decode(Ride.self, from: data)
    let creator = User(id: "creator1", firstName: "Mohamed", lastName: "Mami", gender: "M", email: "m@m.com", birthday: nil, avatar: nil, role: "USER", password: nil)
    return NavigationStack { SortieDetailView(ride: ride, creator: creator) }
}

// MARK: - SinglePointMap fallback
import MapKit
private struct SinglePointMap: View {
    let center: CLLocationCoordinate2D
    @State private var region: MKCoordinateRegion
    init(center: CLLocationCoordinate2D) {
        self.center = center
        _region = State(initialValue: MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)))
    }
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [IdentifiableCoord(center)]) { item in
            MapMarker(coordinate: item.coord, tint: .green)
        }
    }
    private struct IdentifiableCoord: Identifiable { let id = UUID(); let coord: CLLocationCoordinate2D; init(_ c: CLLocationCoordinate2D){ self.coord = c } }
}
