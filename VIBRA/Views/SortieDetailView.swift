//  SortieDetailView.swift
//  VIBRA
//
//  Created by ChatGPT on behalf of Karim
//

import SwiftUI
import CoreLocation
import MapKit

struct SortieDetailView: View {
    @StateObject private var vm: SortieDetailViewModel
    private var isPreview: Bool { ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" }
    @Environment(\.dismiss) private var dismiss

    init(ride: Ride, creator: User?) {
        _vm = StateObject(wrappedValue: SortieDetailViewModel(ride: ride, creator: creator))
    }

    var body: some View {
        ZStack {
            // Fond gradient cohérent avec style VIBRA
            LinearGradient(
                gradient: Gradient(colors: [AppColors.BackgroundGradientStart, AppColors.BackgroundGradientEnd]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    heroHeader
                        .padding(.top, 12)

                    detailsCard
                        .padding(.horizontal)

                    HStack(spacing: 12) {
                        // chips ligne 1
                        infoChips
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Description + Itinéraire + Météo + Participants groupés dans une card
                    VStack(spacing: 12) {
                        descriptionSection

                        // Section météo
                        weatherSection

                        Divider().background(AppColors.DividerColor)

                        mapSection

                        Divider().background(AppColors.DividerColor)

                        // Section participants
                        participantsSection
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppColors.CardDark.opacity(0.9))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppColors.BorderColor, lineWidth: 0.6))
                    )
                    .padding(.horizontal)

                    // Participants / CTA
                    participateButton
                        .padding(.horizontal)
                        .padding(.bottom, 14)
                }
                .padding(.bottom, 10)
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .task {
            if !isPreview {
                await vm.loadRoute()
                await vm.loadWeather()
                await vm.loadParticipations() // IMPORTANT: charge les participations pour gérer "Déjà inscrit" + membres ACCEPTÉE
            }
        }
    }

    // MARK: - Hero Header (Image + Overlay + back)
    private var heroHeader: some View {
        ZStack(alignment: .topLeading) {
            AsyncImageView(urlString: vm.ride.photo)
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    // gradient overlay pour lisibilité
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.45), Color.clear, Color.black.opacity(0.30)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                )

            // back button
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(AppColors.CardGlass)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppColors.DividerColor, lineWidth: 0.6))
                    .shadow(color: AppColors.ShadowColor, radius: 6, x: 0, y: 3)
            }
            .padding(.leading, 18)
            .padding(.top, 14)
        }
        .padding(.horizontal)
    }

    // MARK: - Details Card
    private var detailsCard: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(vm.ride.titre)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.TextPrimary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    creatorAvatar
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vm.creatorFullName)
                            .font(.subheadline)
                            .foregroundColor(AppColors.TextPrimary)
                        Text("Organisateur")
                            .font(.caption)
                            .foregroundColor(AppColors.TextTertiary)
                    }
                    Spacer()
                }
            }

            Spacer()

            // mini-card droite: type + date shortcut
            VStack(alignment: .trailing, spacing: 8) {
                Text(vm.ride.type?.capitalized ?? "")
                    .font(.caption.weight(.semibold))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(AppColors.CardGlass)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.DividerColor, lineWidth: 0.6))

                Text(vm.dateOnly)
                    .font(.caption2)
                    .foregroundColor(AppColors.TextTertiary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.CardDark.opacity(0.95))
        )
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.BorderColor, lineWidth: 0.6))
        .shadow(color: AppColors.ShadowColor, radius: 10, x: 0, y: 6)
    }

    // MARK: - Avatar
    private var creatorAvatar: some View {
        Group {
            if let urlStr = vm.creator?.avatar, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Circle().fill(AppColors.CardGlass)
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Circle().fill(AppColors.CardGlass)
                            .overlay(Image(systemName: "person.fill").foregroundColor(AppColors.TextTertiary))
                    @unknown default:
                        Circle().fill(AppColors.CardGlass)
                    }
                }
            } else {
                Circle()
                    .fill(AppColors.CardGlass)
                    .overlay(Image(systemName: "person.fill").foregroundColor(AppColors.TextTertiary))
            }
        }
        .frame(width: 46, height: 46)
        .clipShape(Circle())
        .overlay(Circle().stroke(AppColors.DividerColor, lineWidth: 1.2))
        .shadow(color: AppColors.ShadowColor, radius: 6, x: 0, y: 3)
    }

    // MARK: - Info Chips
    private var infoChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                chip(icon: "calendar", text: vm.dateOnly)
                chip(icon: "clock", text: vm.timeOnly)
                if let dist = vm.ride.distance { chip(icon: "ruler", text: distanceText(dist)) }
                if let diff = vm.ride.difficulte, !diff.isEmpty { chip(icon: "gauge", text: diff.capitalized) }
            }

            HStack(spacing: 8) {
                let pCount = max(vm.participants.count, vm.participantIds.count)
                let cap = vm.ride.capacite
                if pCount > 0 || cap != nil {
                    let label = cap != nil ? "\(pCount) / \(cap!)" : "\(pCount)"
                    chip(icon: "person.2", text: label)
                }
                if includesCamping(vm.ride) { chip(icon: "tent.fill", text: "Camping") }
            }
        }
    }

    private func chip(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.GreenAccent)
            Text(text)
                .font(.caption)
                .foregroundColor(AppColors.TextPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(AppColors.CardGlass)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.DividerColor, lineWidth: 0.6))
        .shadow(color: AppColors.ShadowColor.opacity(0.6), radius: 6, x: 0, y: 3)
    }

    private func includesCamping(_ ride: Ride) -> Bool {
        if let flag = ride.optionCamping, flag { return true }
        if ride.campingId != nil { return true }
        if ride.camping != nil { return true }
        return false
    }

    // MARK: - Map Section
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Itinéraire")
                    .font(.headline)
                    .foregroundColor(AppColors.TextPrimary)
                Spacer()
                if vm.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.GreenAccent))
                }
            }

            let start = vm.startCoordinate
            let end = vm.endCoordinate

            if let s = start, let e = end {
                RouteMapView(routeCoordinates: vm.routeCoordinates, startCoordinate: s, endCoordinate: e)
                    .frame(height: 260)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.DividerColor, lineWidth: 0.6))
            } else if let single = start ?? end {
                SinglePointMap(center: single)
                    .frame(height: 220)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.DividerColor, lineWidth: 0.6))
            } else {
                Text("Points de départ/arrivée non disponibles")
                    .font(.subheadline)
                    .foregroundColor(AppColors.TextTertiary)
                    .padding(.vertical, 18)
            }
        }
    }

    // MARK: - Weather Section
    private var weatherSection: some View {
        Group {
            if vm.weatherAvailable {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Météo prévue")
                            .font(.headline)
                            .foregroundColor(AppColors.TextPrimary)
                        Spacer()
                        if vm.isLoadingWeather {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.GreenAccent))
                        }
                    }

                    HStack(spacing: 12) {
                        Image(systemName: vm.weatherIconName)
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.GreenAccent)

                        VStack(alignment: .leading, spacing: 4) {
                            if let desc = vm.weatherSummary {
                                Text(desc)
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.TextPrimary)
                            }

                            if let temp = vm.weatherTemperatureText {
                                Text(temp)
                                    .font(.footnote)
                                    .foregroundColor(AppColors.TextSecondary)
                            }

                            if let wind = vm.weatherWindText {
                                Text(wind)
                                    .font(.footnote)
                                    .foregroundColor(AppColors.TextSecondary)
                            }
                        }
                    }
                }
            } else if vm.isLoadingWeather {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Météo prévue")
                            .font(.headline)
                            .foregroundColor(AppColors.TextPrimary)
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.GreenAccent))
                    }
                }
            } else if let error = vm.weatherErrorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Météo")
                        .font(.headline)
                        .foregroundColor(AppColors.TextPrimary)
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                }
            } else {
                // Pas de météo disponible et pas d'erreur -> ne rien afficher
                EmptyView()
            }
        }
    }

    // MARK: - Participants Section
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Participants")
                    .font(.headline)
                    .foregroundColor(AppColors.TextPrimary)
                Spacer()
                let count = max(vm.participants.count, vm.participantIds.count)
                if count > 0 {
                    Text("\(count) inscrit\(count > 1 ? "s" : "")")
                        .font(.footnote)
                        .foregroundColor(AppColors.TextSecondary)
                }
            }

            if vm.participants.isEmpty && vm.participantIds.isEmpty {
                Text("Aucun participant pour le moment")
                    .font(.footnote)
                    .foregroundColor(AppColors.TextTertiary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    // Participants complets (User)
                    ForEach(vm.participants, id: \.id) { user in
                        ParticipantRow(user: user)
                    }

                    // IDs sans user chargé (au cas où)
                    let remainingIds = vm.participantIds.filter { pid in
                        !vm.participants.contains(where: { $0.id == pid })
                    }
                    if !remainingIds.isEmpty {
                        ForEach(remainingIds, id: \.self) { pid in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(AppColors.CardGlass)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.TextTertiary)
                                    )
                                Text("Participant \(pid.prefix(6))…")
                                    .font(.footnote)
                                    .foregroundColor(AppColors.TextSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Participate Button
    private var participateButton: some View {
        VStack(spacing: 10) {
            Button {
                Task { await vm.participate() }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [AppColors.GreenAccent, AppColors.GreenDark]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .shadow(color: AppColors.GlowGreen.opacity(0.8), radius: 12, x: 0, y: 6)

                    if vm.isParticipating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    } else {
                        Text(vm.alreadyParticipating ? "Déjà inscrit" : "Participer")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.black)
                    }
                }
                .frame(height: 52)
            }
            .disabled(vm.isParticipating || vm.alreadyParticipating)
            .opacity((vm.isParticipating || vm.alreadyParticipating) ? 0.9 : 1.0)

            if let msg = vm.participationMessage, !msg.isEmpty {
                Text(msg)
                    .font(.footnote)
                    .foregroundColor(msg.lowercased().contains("échec") ? .red : AppColors.GreenAccent)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Description
    private var descriptionSection: some View {
        Group {
            if let d = vm.ride.description, !d.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Description")
                        .font(.headline)
                        .foregroundColor(AppColors.TextPrimary)
                    Text(d)
                        .font(.subheadline)
                        .foregroundColor(AppColors.TextPrimary.opacity(0.95))
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                EmptyView()
            }
        }
    }

    // MARK: - Utilities
    private func distanceText(_ meters: Int) -> String {
        if meters >= 1000 { return String(format: "%.1f km", Double(meters) / 1000.0) }
        return "\(meters) m"
    }
}

// MARK: - Participant Row
private struct ParticipantRow: View {
    let user: User

    private var initials: String {
        let f = user.firstName.first.map(String.init) ?? ""
        let l = user.lastName.first.map(String.init) ?? ""
        let txt = (f + l)
        return txt.isEmpty ? "?" : txt.uppercased()
    }

    var body: some View {
        HStack(spacing: 10) {
            if let avatar = user.avatar, let url = URL(string: avatar) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(AppColors.CardGlass)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Circle()
                            .fill(AppColors.CardGlass)
                            .overlay(Text(initials)
                                .font(.caption.bold())
                                .foregroundColor(AppColors.TextPrimary))
                    @unknown default:
                        Circle().fill(AppColors.CardGlass)
                    }
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .overlay(Circle().stroke(AppColors.DividerColor, lineWidth: 0.8))
            } else {
                Circle()
                    .fill(AppColors.CardGlass)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(initials)
                            .font(.caption.bold())
                            .foregroundColor(AppColors.TextPrimary)
                    )
                    .overlay(Circle().stroke(AppColors.DividerColor, lineWidth: 0.8))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.footnote)
                    .foregroundColor(AppColors.TextPrimary)
                Text(user.email)
                    .font(.caption2)
                    .foregroundColor(AppColors.TextSecondary)
            }

            Spacer()
        }
    }
}

// MARK: - AsyncImageView helper (réutilisable et pro)
private struct AsyncImageView: View {
    let urlString: String?
    var body: some View {
        Group {
            if let s = urlString, let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Rectangle().fill(AppColors.CardGlass)
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppColors.GreenAccent))
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        ZStack {
                            Rectangle().fill(AppColors.CardGlass)
                            Image(systemName: "photo.fill.on.rectangle.fill")
                                .font(.largeTitle)
                                .foregroundColor(AppColors.TextTertiary)
                        }
                    @unknown default:
                        Rectangle().fill(AppColors.CardGlass)
                    }
                }
            } else {
                ZStack {
                    Rectangle().fill(AppColors.CardGlass)
                    Image(systemName: "photo.fill.on.rectangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(AppColors.TextTertiary)
                }
            }
        }
        .clipped()
    }
}

// MARK: - SinglePointMap fallback (déjà fourni)
private struct SinglePointMap: View {
    let center: CLLocationCoordinate2D
    @State private var region: MKCoordinateRegion

    init(center: CLLocationCoordinate2D) {
        self.center = center
        _region = State(initialValue: MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)))
    }

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [IdentifiableCoord(center)]) { item in
            MapMarker(coordinate: item.coord, tint: AppColors.GreenAccent)
        }
        .cornerRadius(12)
    }

    private struct IdentifiableCoord: Identifiable {
        let id = UUID()
        let coord: CLLocationCoordinate2D
        init(_ c: CLLocationCoordinate2D) { self.coord = c }
    }
}
/*
 // MARK: - Preview
 #Preview {
 let data = """
 {
 "_id": "preview1",
 "titre": "Balade test",
 "description": "Aperçu de la sortie — description complète pour voir l'affichage dans la vue.",
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
 "difficulte": "moyen",
 "participantIds": ["u1","u2"]
 }
 """.data(using: .utf8)!
 let ride = try! JSONDecoder().decode(Ride.self, from: data)
 let creator = User(id: "creator1", firstName: "Mohamed", lastName: "Mami", gender: "M", email: "m@m.com", birthday: nil, avatar: nil, role: "USER", password: nil)
 NavigationStack { SortieDetailView(ride: ride, creator: creator) }
 }
 */
