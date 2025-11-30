//
//  CreateSortieView.swift
//  VIBRA
//

import SwiftUI
import MapKit
import CoreLocation
import PhotosUI

struct CreateSortieView: View {

    @StateObject private var viewModel = CreateSortieViewModel()
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var isSelectingStart = true
    @State private var currentStep = 1
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColors.BackgroundGradientStart,
                        AppColors.BackgroundGradientEnd
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Header avec indicateur de progression
                    stepIndicator
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 16)
                    
                    // MARK: - Contenu de l'étape actuelle
                    TabView(selection: $currentStep) {
                        step1Content
                            .tag(1)
                        
                        step2Content
                            .tag(2)
                        
                        step3Content
                            .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                    
                    // MARK: - Boutons de navigation
                    navigationButtons
                        .padding()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .alert("Erreur", isPresented: $viewModel.showErrorAlert, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(viewModel.errorMessage ?? "Une erreur est survenue.")
            })
            .alert("Succès", isPresented: $viewModel.showSuccessAlert, actions: {
                Button("OK", role: .cancel) {
                    currentStep = 1
                }
            }, message: {
                Text(viewModel.successMessage ?? "Opération réussie.")
            })
        }
    }
    
    // MARK: - Step Indicator
    
    private var stepIndicator: some View {
        HStack(spacing: 12) {
            ForEach(1...3, id: \.self) { step in
                VStack(spacing: 8) {
                    Circle()
                        .fill(currentStep >= step ? AppColors.GreenAccent : AppColors.CardGlass)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text("\(step)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(currentStep >= step ? .black : AppColors.TextTertiary)
                        )
                    
                    Text(stepTitle(for: step))
                        .font(.caption2)
                        .foregroundColor(currentStep == step ? AppColors.GreenAccent : AppColors.TextTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                
                if step < 3 {
                    Rectangle()
                        .fill(currentStep > step ? AppColors.GreenAccent : AppColors.CardGlass)
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppColors.CardDark.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppColors.BorderColor, lineWidth: 0.7)
                )
        )
        .shadow(color: AppColors.ShadowColor, radius: 8, x: 0, y: 4)
    }
    
    private func stepTitle(for step: Int) -> String {
        switch step {
        case 1: return "Informations"
        case 2: return "Itinéraire"
        case 3: return "Camping"
        default: return ""
        }
    }
    
    // MARK: - Step 1: Informations de la sortie
    
    private var step1Content: some View {
        ScrollView {
            VStack(spacing: 20) {
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
                            Text("Camping").tag("CAMPING")
                        }
                        .pickerStyle(.segmented)
                        .tint(AppColors.TealAccent)

                        // Sélection d'image
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Photo de la sortie (optionnel)")
                                .font(.subheadline)
                                .foregroundColor(AppColors.TextSecondary)

                            HStack(spacing: 12) {
                                PhotosPicker(
                                    selection: $viewModel.selectedPhotoItem,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    HStack {
                                        Image(systemName: "photo.on.rectangle")
                                        Text(viewModel.selectedPhotoItem == nil ? "Choisir une image" : "Changer l'image")
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(AppColors.CardGlass)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(AppColors.DividerColor, lineWidth: 0.7)
                                    )
                                }

                                if let image = viewModel.selectedUIImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(AppColors.DividerColor, lineWidth: 0.7)
                                        )
                                }
                            }

                            if viewModel.isLoadingImage {
                                ProgressView("Chargement de l'image…")
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.GreenAccent))
                                    .font(.footnote)
                            }
                        }

                        TextField("Capacité (optionnel)", value: $viewModel.capacite, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .modifier(VibraFieldModifier())
                        
                        vibraTextField("Difficulté (ex: FACILE, MOYEN, DIFFICILE)", text: $viewModel.difficulte)
                        vibraTextField("Niveau (ex: DEBUTANT, INTERMEDIAIRE, AVANCE)", text: $viewModel.niveau)
                        
                        TextField("Prix de la sortie (optionnel)", value: $viewModel.prixSortie, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .modifier(VibraFieldModifier())
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Step 2: Itinéraire
    
    private var step2Content: some View {
        ScrollView {
            VStack(spacing: 20) {
                styledGroupBox(title: "Itinéraire", systemImage: "map") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choisissez le point de départ et d'arrivée sur la carte, puis calculez l'itinéraire.")
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
                        .frame(height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: AppColors.ShadowColor, radius: 10, x: 0, y: 5)

                        if viewModel.isFetchingRoute {
                            ProgressView("Calcul de l'itinéraire…")
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.GreenAccent))
                        } else {
                            Button("Calculer l'itinéraire") {
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
            }
            .padding()
        }
    }
    
    // MARK: - Step 3: Camping
    
    private var step3Content: some View {
        ScrollView {
            VStack(spacing: 20) {
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
                        } else {
                            Text("Vous pouvez passer cette étape si vous ne souhaitez pas inclure de camping.")
                                .font(.footnote)
                                .foregroundColor(AppColors.TextTertiary)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 12) {
            // Bouton Précédent
            if currentStep > 1 {
                Button {
                    withAnimation {
                        currentStep -= 1
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Précédent")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.TextPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppColors.CardGlass)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(AppColors.DividerColor, lineWidth: 1)
                            )
                    )
                }
            }
            
            // Bouton Suivant / Créer
            Button {
                if currentStep < 3 {
                    // Validation de l'étape courante
                    if validateCurrentStep() {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                } else {
                    // Créer la sortie
                    Task { await viewModel.createSortieAndCamping() }
                }
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
                        HStack {
                            Text(currentStep < 3 ? "Suivant" : "Créer la sortie")
                            if currentStep < 3 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }
            .disabled(viewModel.isLoading)
        }
    }
    
    // MARK: - Validation
    
    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case 1:
            if viewModel.titre.isEmpty {
                viewModel.errorMessage = "Le titre de la sortie est obligatoire."
                viewModel.showErrorAlert = true
                return false
            }
            return true
        case 2:
            if viewModel.itineraire == nil {
                viewModel.errorMessage = "Veuillez calculer l'itinéraire avant de continuer."
                viewModel.showErrorAlert = true
                return false
            }
            return true
        case 3:
            if viewModel.optionCamping {
                if viewModel.campingNom.isEmpty || viewModel.campingLieu.isEmpty {
                    viewModel.errorMessage = "Veuillez remplir les informations de camping (nom et lieu)."
                    viewModel.showErrorAlert = true
                    return false
                }
            }
            return true
        default:
            return true
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

// MARK: - MapViewRepresentable

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
