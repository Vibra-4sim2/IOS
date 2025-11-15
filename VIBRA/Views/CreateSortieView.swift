//
//  CreateSortieView.swift
//  VIBRA
//

import SwiftUI
import MapKit
import CoreLocation

struct CreateSortieView: View {

    @StateObject private var viewModel = CreateSortieViewModel()
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var isSelectingStart = true

    var body: some View {
        NavigationView {
            ZStack {
                // Fond dégradé style maquettes
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColors.BackgroundGradientStart,
                        AppColors.BackgroundGradientEnd
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Petit header façon VIBRA
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("VIBRA")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(AppColors.TextPrimary)
                                Text("Créer une nouvelle aventure")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppColors.TextSecondary)
                            }
                            Spacer()
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [AppColors.GreenAccent, AppColors.TealAccent]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 42, height: 42)
                                .shadow(color: AppColors.GlowGreen.opacity(0.7), radius: 10, x: 0, y: 4)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.black)
                                )
                        }

                        // MARK: - Infos sortie
                        styledGroupBox(title: "Informations de la sortie", systemImage: "info.circle") {
                            VStack(alignment: .leading, spacing: 12) {
                                vibraTextField("Titre", text: $viewModel.titre)
                                vibraMultilineField("Description", text: $viewModel.description)

                                DatePicker(
                                    "Date de la sortie",
                                    selection: $viewModel.date,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .accentColor(AppColors.GreenAccent)

                                Picker("Type", selection: $viewModel.type) {
                                    Text("Randonnée").tag("RANDO")
                                    Text("Vélo électrique").tag("VELO_ELECTRIQUE")
                                }
                                .pickerStyle(.segmented)
                                .tint(AppColors.TealAccent)

                                vibraTextField("URL de la photo (optionnel)", text: $viewModel.photoURL)

                                TextField("Capacité (optionnel)", value: $viewModel.capacite, formatter: NumberFormatter())
                                    .keyboardType(.numberPad)
                                    .modifier(VibraFieldModifier())
                            }
                        }

                        // MARK: - Itinéraire
                        styledGroupBox(title: "Itinéraire", systemImage: "map") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Choisissez le point de départ et d’arrivée sur la carte, puis calculez l’itinéraire.")
                                    .font(.footnote)
                                    .foregroundColor(AppColors.TextTertiary)

                                HStack {
                                    vibraTextField("Adresse départ (optionnel)", text: $viewModel.departAddressText)
                                    vibraTextField("Adresse arrivée (optionnel)", text: $viewModel.arriveeAddressText)
                                }

                                HStack {
                                    segmentButton("Départ", systemImage: "mappin", isActive: isSelectingStart) {
                                        isSelectingStart = true
                                    }
                                    segmentButton("Arrivée", systemImage: "mappin.circle", isActive: !isSelectingStart) {
                                        isSelectingStart = false
                                    }
                                }

                                MapViewRepresentable(
                                    region: $mapRegion,
                                    startCoordinate: $viewModel.startCoordinate,
                                    endCoordinate: $viewModel.endCoordinate,
                                    routeCoordinates: $viewModel.routeCoordinates,
                                    isSelectingStart: $isSelectingStart
                                )
                                .frame(height: 230)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: AppColors.ShadowColor, radius: 10, x: 0, y: 5)

                                if viewModel.isFetchingRoute {
                                    ProgressView("Calcul de l’itinéraire…")
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.GreenAccent))
                                } else {
                                    Button("Calculer l’itinéraire") {
                                        Task { await viewModel.fetchRoute() }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(AppColors.TealAccent)
                                    .disabled(viewModel.startCoordinate == nil || viewModel.endCoordinate == nil)
                                }

                                if let itin = viewModel.itineraire {
                                    HStack(spacing: 16) {
                                        if let distance = itin.distance {
                                            let distanceKm = distance / 1000
                                            let distanceText = String(format: "%.1f km", distanceKm)
                                            
                                            infoPill(
                                                title: "Distance",
                                                value: distanceText,
                                                icon: "ruler"
                                            )
                                        }
                                        if let duree = itin.duree_estimee {
                                            let minutes = Int(duree / 60)
                                            infoPill(
                                                title: "Durée estimée",
                                                value: "\(minutes) min",
                                                icon: "clock"
                                            )
                                        }
                                    }
                                }
                            }
                        }

                        // MARK: - Camping
                        styledGroupBox(title: "Camping", systemImage: "tent") {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle("Inclure un camping", isOn: $viewModel.optionCamping)
                                    .tint(AppColors.GreenAccent)

                                if viewModel.optionCamping {
                                    VStack(alignment: .leading, spacing: 12) {
                                        vibraTextField("Nom du camping", text: $viewModel.campingNom)
                                        vibraMultilineField("Description (optionnel)", text: $viewModel.campingDescription)
                                        vibraTextField("Lieu (adresse)", text: $viewModel.campingLieu)

                                        TextField("Prix (optionnel)", value: $viewModel.campingPrix, formatter: NumberFormatter())
                                            .keyboardType(.decimalPad)
                                            .modifier(VibraFieldModifier())

                                        TextField("Nombre de participants (optionnel)", value: $viewModel.campingParticipants, formatter: NumberFormatter())
                                            .keyboardType(.numberPad)
                                            .modifier(VibraFieldModifier())

                                        DatePicker(
                                            "Date début camping",
                                            selection: $viewModel.campingDateDebut,
                                            displayedComponents: [.date, .hourAndMinute]
                                        )
                                        DatePicker(
                                            "Date fin camping",
                                            selection: $viewModel.campingDateFin,
                                            displayedComponents: [.date, .hourAndMinute]
                                        )
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }

                        // MARK: - Messages
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(AppColors.ErrorRed)
                                .font(.footnote)
                        }

                        if let success = viewModel.successMessage {
                            Text(success)
                                .foregroundColor(AppColors.SuccessGreen)
                                .font(.footnote)
                        }

                        // MARK: - CTA principal
                        Button {
                            Task { await viewModel.createSortieAndCamping() }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [AppColors.GreenAccent, AppColors.GreenDark]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: AppColors.GlowGreen.opacity(0.8), radius: 14, x: 0, y: 6)

                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Text("Créer la sortie")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.black)
                                }
                            }
                            .frame(height: 52)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }

    // MARK: - Sous-vues simples pour le style

    private func styledGroupBox<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .foregroundColor(AppColors.TextSecondary)
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppColors.CardDark.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AppColors.BorderColor, lineWidth: 0.7)
                    )
            )
            .shadow(color: AppColors.ShadowColor, radius: 12, x: 0, y: 6)
        }
    }

    private func vibraTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .modifier(VibraFieldModifier())
    }

    private func vibraMultilineField(_ placeholder: String, text: Binding<String>) -> some View {
        ZStack(alignment: .topLeading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .foregroundColor(AppColors.TextTertiary)
                    .font(.system(size: 14))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
            TextEditor(text: text)
                .scrollContentBackground(.hidden)
                .padding(4)
                .foregroundColor(AppColors.TextPrimary)
        }
        .frame(minHeight: 80)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.CardGlass)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColors.DividerColor, lineWidth: 0.7)
        )
    }

    private func segmentButton(_ title: String, systemImage: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.system(size: 13, weight: .semibold))
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isActive ? AppColors.GreenAccent.opacity(0.25) : AppColors.CardGlass)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isActive ? AppColors.GreenAccent : AppColors.DividerColor, lineWidth: 1)
            )
        }
        .foregroundColor(isActive ? AppColors.GreenAccent : AppColors.TextSecondary)
    }

    private func infoPill(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(AppColors.GreenAccent)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppColors.TextTertiary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppColors.GreenAccent)
            }
        }
        .padding(8)
        .background(AppColors.CardGlass)
        .cornerRadius(12)
    }
}

// MARK: - Modificateur commun pour les champs

struct VibraFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(PlainTextFieldStyle())
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.CardGlass)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColors.DividerColor, lineWidth: 0.7)
            )
            .foregroundColor(AppColors.TextPrimary)
            .font(.system(size: 14))
    }
}

// MARK: - MapViewRepresentable inchangé (juste la couleur de route)

struct MapViewRepresentable: UIViewRepresentable {

    @Binding var region: MKCoordinateRegion
    @Binding var startCoordinate: CLLocationCoordinate2D?
    @Binding var endCoordinate: CLLocationCoordinate2D?
    @Binding var routeCoordinates: [CLLocationCoordinate2D]
    @Binding var isSelectingStart: Bool

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.setRegion(region, animated: false)
        map.delegate = context.coordinator

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        map.addGestureRecognizer(tapGesture)
        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(region, animated: false)
        uiView.removeAnnotations(uiView.annotations)
        uiView.removeOverlays(uiView.overlays)

        if let start = startCoordinate {
            let pin = MKPointAnnotation()
            pin.coordinate = start
            pin.title = "Départ"
            uiView.addAnnotation(pin)
        }
        if let end = endCoordinate {
            let pin = MKPointAnnotation()
            pin.coordinate = end
            pin.title = "Arrivée"
            uiView.addAnnotation(pin)
        }
        if routeCoordinates.count > 1 {
            let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
            uiView.addOverlay(polyline)
            uiView.setVisibleMapRect(
                polyline.boundingMapRect,
                edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40),
                animated: true
            )
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable

        init(_ parent: MapViewRepresentable) { self.parent = parent }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coord = mapView.convert(point, toCoordinateFrom: mapView)
            if parent.isSelectingStart { parent.startCoordinate = coord }
            else { parent.endCoordinate = coord }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(AppColors.GreenAccent)
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// MARK: - Preview

struct CreateSortieView_Previews: PreviewProvider {
    static var previews: some View {
        CreateSortieView()
            .preferredColorScheme(.dark)
    }
}
