//
//  CreateSortieView.swift (Partie 1/2)
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
    @State private var showDepartSuggestions = false
    @State private var showArriveeSuggestions = false

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
                    stepIndicator
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 16)

                    TabView(selection: $currentStep) {
                        step1Content.tag(1)
                        step2Content.tag(2)
                        step3Content.tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)

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
            .onAppear {
                viewModel.requestLocationPermission()
            }
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

    // MARK: - Step 2: Itinéraire (standard + IA)

    private var step2Content: some View {
        ScrollView {
            VStack(spacing: 20) {
                styledGroupBox(title: "Itinéraire", systemImage: "map") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recherchez des adresses ou tapez sur la carte pour définir votre itinéraire.")
                            .font(.footnote)
                            .foregroundColor(AppColors.TextTertiary)

                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(AppColors.GreenAccent)
                                    TextField("Rechercher point de départ", text: $viewModel.departAddressText)
                                        .modifier(VibraFieldModifier())
                                        .onChange(of: viewModel.departAddressText) { _ in
                                            showDepartSuggestions = !viewModel.departAddressText.isEmpty
                                        }
                                }

                                if showDepartSuggestions && !viewModel.departSearchResults.isEmpty {
                                    SearchSuggestionsView(
                                        results: viewModel.departSearchResults,
                                        onSelect: { item in
                                            viewModel.selectDepartureAddress(item)
                                            showDepartSuggestions = false
                                        }
                                    )
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "mappin.circle")
                                        .foregroundColor(AppColors.TealAccent)
                                    TextField("Rechercher point d'arrivée", text: $viewModel.arriveeAddressText)
                                        .modifier(VibraFieldModifier())
                                        .onChange(of: viewModel.arriveeAddressText) { _ in
                                            showArriveeSuggestions = !viewModel.arriveeAddressText.isEmpty
                                        }
                                }

                                if showArriveeSuggestions && !viewModel.arriveeSearchResults.isEmpty {
                                    SearchSuggestionsView(
                                        results: viewModel.arriveeSearchResults,
                                        onSelect: { item in
                                            viewModel.selectArrivalAddress(item)
                                            showArriveeSuggestions = false
                                        }
                                    )
                                }
                            }
                        }

                        HStack {
                            segmentButton("Départ", systemImage: "mappin", isActive: isSelectingStart) {
                                isSelectingStart = true
                            }
                            segmentButton("Arrivée", systemImage: "mappin.circle", isActive: !isSelectingStart) {
                                isSelectingStart = false
                            }
                        }

                        ImprovedMapView(
                            region: $mapRegion,
                            startCoordinate: $viewModel.startCoordinate,
                            endCoordinate: $viewModel.endCoordinate,
                            routeCoordinates: $viewModel.routeCoordinates,
                            userLocation: $viewModel.userLocation,
                            isSelectingStart: $isSelectingStart,
                            onCoordinateSelected: { coord in
                                if isSelectingStart {
                                    viewModel.setStartCoordinate(coord)
                                } else {
                                    viewModel.setEndCoordinate(coord)
                                }
                            }
                        )
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: AppColors.ShadowColor, radius: 10, x: 0, y: 5)

                        // Boutons itinéraire
                        if viewModel.isFetchingRoute || viewModel.isGeneratingAIRoute {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.GreenAccent))
                                Text(viewModel.isGeneratingAIRoute ? "Génération IA en cours…" : "Calcul de l'itinéraire…")
                                    .font(.footnote)
                                    .foregroundColor(AppColors.TextSecondary)
                            }
                            .padding(.vertical, 8)
                        } else {
                            HStack(spacing: 12) {
                                Button {
                                    Task { await viewModel.fetchRoute() }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "map")
                                        Text("Standard")
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(AppColors.TealAccent)
                                    )
                                }
                                .disabled(viewModel.startCoordinate == nil || viewModel.endCoordinate == nil)
                                .opacity((viewModel.startCoordinate == nil || viewModel.endCoordinate == nil) ? 0.5 : 1)

                                Button {
                                    Task { await viewModel.generateAIItinerary() }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "sparkles")
                                        Text("IA")
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.purple.opacity(0.85),
                                                Color.blue.opacity(0.85)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .shadow(color: Color.purple.opacity(0.35), radius: 8, x: 0, y: 4)
                                }
                                .disabled(viewModel.startCoordinate == nil || viewModel.endCoordinate == nil)
                                .opacity((viewModel.startCoordinate == nil || viewModel.endCoordinate == nil) ? 0.5 : 1)
                            }
                        }

                        // Contexte IA optionnel
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "text.bubble")
                                    .foregroundColor(AppColors.TextTertiary)
                                Text("Préférences IA (optionnel)")
                                    .font(.caption)
                                    .foregroundColor(AppColors.TextTertiary)
                            }

                            TextField("Ex: Je préfère les routes ombragées", text: $viewModel.aiContext)
                                .modifier(VibraFieldModifier())
                        }

                        // Infos itinéraire
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

                        // Recommandations IA
                        if viewModel.showAIRecommendations, let aiResponse = viewModel.aiItineraryResponse {
                            aiRecommendationsCard(aiResponse: aiResponse)
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Step 3: Camping (inchangé)

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
}

// MARK: - Extension CreateSortieView (Navigation & Helpers)

extension CreateSortieView {

    // MARK: - Navigation Buttons

    var navigationButtons: some View {
        HStack(spacing: 12) {
            if currentStep > 1 {
                Button {
                    withAnimation { currentStep -= 1 }
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

            Button {
                if currentStep < 3 {
                    if validateCurrentStep() {
                        withAnimation { currentStep += 1 }
                    }
                } else {
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
                        ProgressView().tint(.black)
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

    func validateCurrentStep() -> Bool {
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

    func styledGroupBox<Content: View>(
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

    func vibraTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .modifier(VibraFieldModifier())
    }

    func vibraMultilineField(_ placeholder: String, text: Binding<String>) -> some View {
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

    func segmentButton(_ title: String, systemImage: String, isActive: Bool, action: @escaping () -> Void) -> some View {
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

    func infoPill(title: String, value: String, icon: String) -> some View {
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

    // MARK: - AI Recommendations Card

    @ViewBuilder
    func aiRecommendationsCard(aiResponse: AIItineraryResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Recommandations IA")
                    .font(.headline)
                    .foregroundColor(AppColors.TextPrimary)
                Spacer()
                Button {
                    withAnimation {
                        viewModel.showAIRecommendations = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.TextTertiary)
                }
            }

            Divider()
                .background(AppColors.DividerColor)

            HStack {
                aiInfoBadge(
                    title: "Difficulté",
                    value: aiResponse.personalization.difficultyAssessment.capitalized,
                    icon: "figure.hiking",
                    color: difficultyColor(score: aiResponse.personalization.difficultyScore)
                )

                aiInfoBadge(
                    title: "Meilleur moment",
                    value: aiResponse.aiRecommendations.bestTimeOfDay.capitalized,
                    icon: "sun.max",
                    color: .orange
                )
            }

            if !aiResponse.aiRecommendations.safetyTips.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "shield.checkered")
                            .foregroundColor(.green)
                        Text("Sécurité")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppColors.TextSecondary)
                    }

                    ForEach(aiResponse.aiRecommendations.safetyTips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.GreenAccent)
                                .font(.caption)
                            Text(tip)
                                .font(.caption)
                                .foregroundColor(AppColors.TextSecondary)
                        }
                    }
                }
            }

            if !aiResponse.aiRecommendations.equipmentSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "bag")
                            .foregroundColor(.blue)
                        Text("Équipement")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppColors.TextSecondary)
                    }

                    // simple wrap using LazyVGrid
                    let columns = [GridItem(.adaptive(minimum: 120), spacing: 8)]
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                        ForEach(aiResponse.aiRecommendations.equipmentSuggestions, id: \.self) { item in
                            Text(item)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppColors.CardGlass)
                                .cornerRadius(8)
                                .foregroundColor(AppColors.TextPrimary)
                        }
                    }
                }
            }

            if !aiResponse.aiRecommendations.weatherConsiderations.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "cloud.sun")
                        .foregroundColor(.cyan)
                    Text(aiResponse.aiRecommendations.weatherConsiderations)
                        .font(.caption)
                        .foregroundColor(AppColors.TextSecondary)
                }
            }

            if !aiResponse.aiRecommendations.personalizedTips.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "lightbulb")
                            .foregroundColor(.yellow)
                        Text("Conseils personnalisés")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppColors.TextSecondary)
                    }
                    ForEach(aiResponse.aiRecommendations.personalizedTips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "sparkle")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(tip)
                                .font(.caption)
                                .foregroundColor(AppColors.TextSecondary)
                        }
                    }
                }
            }

            if !aiResponse.aiRecommendations.suggestedStops.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "flag")
                            .foregroundColor(.purple)
                        Text("Stops suggérés")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppColors.TextSecondary)
                    }
                    ForEach(aiResponse.aiRecommendations.suggestedStops, id: \.self) { stop in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.purple)
                                .font(.caption)
                            Text(stop)
                                .font(.caption)
                                .foregroundColor(AppColors.TextSecondary)
                        }
                    }
                }
            }

            if !aiResponse.aiRecommendations.alternativeSuggestion.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "arrow.triangle.branch")
                            .foregroundColor(.pink)
                        Text("Alternative")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppColors.TextSecondary)
                    }
                    Text(aiResponse.aiRecommendations.alternativeSuggestion)
                        .font(.caption)
                        .foregroundColor(AppColors.TextSecondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.purple.opacity(0.12),
                            Color.blue.opacity(0.10)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.purple.opacity(0.25), lineWidth: 1)
                )
        )
    }

    func aiInfoBadge(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(AppColors.TextTertiary)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(color)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(AppColors.CardGlass)
        .cornerRadius(10)
    }

    func difficultyColor(score: Int) -> Color {
        switch score {
        case ..<3: return .green
        case 3...6: return .orange
        default: return .red
        }
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

// MARK: - SearchSuggestionsView (Autocomplétion)

struct SearchSuggestionsView: View {
    let results: [MKMapItem]
    let onSelect: (MKMapItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(results.prefix(5), id: \.self) { item in
                Button {
                    onSelect(item)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(AppColors.GreenAccent)
                            .font(.system(size: 14))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name ?? "")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.TextPrimary)

                            if let address = item.placemark.title {
                                Text(address)
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColors.TextTertiary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                }

                if item != results.prefix(5).last {
                    Divider().background(AppColors.DividerColor)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.CardDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppColors.BorderColor, lineWidth: 0.7)
                )
        )
        .shadow(color: AppColors.ShadowColor, radius: 8, x: 0, y: 4)
    }
}

// MARK: - ImprovedMapView avec géolocalisation

struct ImprovedMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var startCoordinate: CLLocationCoordinate2D?
    @Binding var endCoordinate: CLLocationCoordinate2D?
    @Binding var routeCoordinates: [CLLocationCoordinate2D]
    @Binding var userLocation: CLLocationCoordinate2D?
    @Binding var isSelectingStart: Bool

    let onCoordinateSelected: (CLLocationCoordinate2D) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.userTrackingMode = .follow

        map.setRegion(region, animated: false)

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        map.addGestureRecognizer(tapGesture)

        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if let userLoc = userLocation {
            let region = MKCoordinateRegion(
                center: userLoc,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            uiView.setRegion(region, animated: true)
        }

        uiView.removeAnnotations(uiView.annotations.filter { !($0 is MKUserLocation) })
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
                edgePadding: UIEdgeInsets(top: 60, left: 60, bottom: 60, right: 60),
                animated: true
            )
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ImprovedMapView

        init(_ parent: ImprovedMapView) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coord = mapView.convert(point, toCoordinateFrom: mapView)
            parent.onCoordinateSelected(coord)
        }

        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            if let location = userLocation.location {
                DispatchQueue.main.async {
                    self.parent.userLocation = location.coordinate
                }
            }
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

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            let identifier = "CustomPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }

            if let markerView = annotationView as? MKMarkerAnnotationView {
                if annotation.title == "Départ" {
                    markerView.markerTintColor = UIColor(AppColors.GreenAccent)
                    markerView.glyphImage = UIImage(systemName: "mappin.circle.fill")
                } else if annotation.title == "Arrivée" {
                    markerView.markerTintColor = UIColor(AppColors.TealAccent)
                    markerView.glyphImage = UIImage(systemName: "flag.fill")
                }
            }

            return annotationView
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
