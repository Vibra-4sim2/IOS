//
//  MapView.swift
//  VIBRA
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @StateObject private var rideLocationManager = RideLocationManager()
    @Environment(\.dismiss) private var dismiss
    
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var showFilters = false
    
    // Only show back button when pushed via NavigationLink (not when in TabBar)
    var showBackButton: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(coordinateRegion: $viewModel.mapRegion,
                    interactionModes: .all,
                    showsUserLocation: true,
                    userTrackingMode: $userTrackingMode,
                    annotationItems: viewModel.mapAnnotations) { annotation in
                    MapAnnotation(coordinate: annotation.coordinate) {
                        RideMapPin(annotation: annotation) {
                            viewModel.selectedRide = annotation.rideWithCreator
                        }
                    }
                }
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    topBar
                    
                    if viewModel.isLoading {
                        loadingOverlay
                    }
                    
                    Spacer()
                    
                    if let selectedRide = viewModel.selectedRide {
                        selectedRideCard(selectedRide)
                            .transition(.move(edge: .bottom))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
            .task {
                await viewModel.load()
                rideLocationManager.requestLocation()
            }
            .sheet(isPresented: $showFilters) {
                MapFiltersSheet(viewModel: viewModel)
            }
        }
    }
    
    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                // Back Button - only show when pushed via NavigationLink
                if showBackButton {
                    Button {
                        dismiss()
                    } label: {
                        Circle()
                            .fill(AppColors.CardDark)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppColors.GreenAccent)
                            )
                    }
                }
                
                Text("Carte des sorties")
                    .font(.title2.bold())
                    .foregroundColor(AppColors.TextPrimary)
                
                Spacer()
                
                Button {
                    showFilters = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(AppColors.CardDark)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(AppColors.GreenAccent)
                        
                        if viewModel.activeFiltersCount > 0 {
                            Circle()
                                .fill(AppColors.GreenAccent)
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Text("\(viewModel.activeFiltersCount)")
                                        .font(.caption2.bold())
                                        .foregroundColor(.black)
                                )
                                .offset(x: 12, y: -12)
                        }
                    }
                }
                
                Button {
                    if let userLocation = rideLocationManager.location?.coordinate {
                        viewModel.centerOnUserLocation(userLocation)
                        userTrackingMode = .follow
                    }
                } label: {
                    Circle()
                        .fill(AppColors.CardDark)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "location.fill")
                                .foregroundColor(AppColors.GreenAccent)
                        )
                }
            }
            .padding()
            .background(
                AppColors.CardDark.opacity(0.95)
                    .blur(radius: 10)
            )
            .cornerRadius(16)
            .shadow(color: AppColors.ShadowColor.opacity(0.3), radius: 10)
            
            HStack(spacing: 8) {
                Text("📍 \(viewModel.filteredItems.count) sortie(s)")
                    .font(.caption.bold())
                    .foregroundColor(AppColors.TextPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.CardDark.opacity(0.95))
                    .cornerRadius(12)
                
                if viewModel.activeFiltersCount > 0 {
                    Button {
                        viewModel.resetFilters()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                            Text("Réinitialiser")
                                .font(.caption2)
                        }
                        .foregroundColor(AppColors.TextSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(AppColors.CardGlass)
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.top, 50)
        .padding(.horizontal)
    }
    
    private var loadingOverlay: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.GreenAccent))
            Text("Chargement des sorties...")
                .font(.caption)
                .foregroundColor(AppColors.TextSecondary)
        }
        .padding()
        .background(AppColors.CardDark.opacity(0.95))
        .cornerRadius(16)
        .shadow(color: AppColors.ShadowColor.opacity(0.3), radius: 10)
    }
    
    @ViewBuilder
    private func selectedRideCard(_ item: RideWithCreator) -> some View {
        NavigationLink(destination: SortieDetailView(ride: item.ride, creator: item.creator)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            if let type = item.ride.type {
                                Text(type)
                                    .font(.caption.bold())
                                    .foregroundColor(AppColors.GreenAccent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(AppColors.GreenAccent.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            
                            Spacer()
                            
                            Button {
                                viewModel.selectedRide = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppColors.TextSecondary)
                            }
                        }
                        
                        Text(item.ride.titre)
                            .font(.headline.bold())
                            .foregroundColor(AppColors.TextPrimary)
                            .lineLimit(2)
                        
                        if let date = item.ride.date {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                    .foregroundColor(AppColors.TextSecondary)
                                Text(formatDate(date))
                                    .font(.caption)
                                    .foregroundColor(AppColors.TextSecondary)
                            }
                        }
                        
                        if let creator = item.creator {
                            HStack(spacing: 6) {
                                Image(systemName: "person.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(AppColors.GreenAccent)
                                Text("\(creator.firstName ?? "") \(creator.lastName ?? "")")
                                    .font(.caption)
                                    .foregroundColor(AppColors.TextPrimary)
                            }
                        }
                    }
                }
                
                HStack {
                    Spacer()
                    Text("Voir les détails")
                        .font(.caption.bold())
                        .foregroundColor(AppColors.GreenAccent)
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundColor(AppColors.GreenAccent)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.CardDark)
                    .shadow(color: AppColors.ShadowColor.opacity(0.5), radius: 20)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppColors.GreenAccent.opacity(0.3), lineWidth: 1)
            )
            .padding()
        }
        .buttonStyle(.plain)
    }
    
    private func formatDate(_ dateString: String) -> String {
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
            if let date = formatter.date(from: dateString) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateStyle = .medium
                displayFormatter.timeStyle = .short
                displayFormatter.locale = Locale(identifier: "fr_FR")
                return displayFormatter.string(from: date)
            }
        }
        
        return dateString
    }
}

struct RideMapPin: View {
    let annotation: RideAnnotation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(AppColors.GreenAccent)
                    .frame(width: 40, height: 40)
                    .shadow(color: AppColors.GlowGreen.opacity(0.7), radius: 10)
                
                Image(systemName: annotation.type?.uppercased().contains("VELO") == true || annotation.type?.uppercased().contains("BIKE") == true ? "bicycle" : "figure.hiking")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
            }
        }
    }
}

struct MapFiltersSheet: View {
    @ObservedObject var viewModel: MapViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [AppColors.BackgroundGradientStart, AppColors.BackgroundGradientEnd]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        HStack(spacing: 10) {
                            MapFilterButton(
                                title: "Followers",
                                isSelected: viewModel.selectedTab == "Followers"
                            ) {
                                viewModel.selectedTab = "Followers"
                                Task {
                                    await viewModel.onTabChange()
                                    dismiss()
                                }
                            }

                            MapFilterButton(
                                title: "Recommendation",
                                isSelected: viewModel.selectedTab == "Recommendation"
                            ) {
                                viewModel.selectedTab = "Recommendation"
                                Task {
                                    await viewModel.onTabChange()
                                    dismiss()
                                }
                            }

                            MapFilterButton(
                                title: "Explore",
                                isSelected: viewModel.selectedTab == "Explore"
                            ) {
                                viewModel.selectedTab = "Explore"
                                Task {
                                    await viewModel.onTabChange()
                                    dismiss()
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Type d'activité")
                                .font(.headline)
                                .foregroundColor(AppColors.TextPrimary)
                            
                            HStack(spacing: 10) {
                                MapActivityButton(
                                    title: "All",
                                    isSelected: viewModel.selectedActivity == "All"
                                ) {
                                    viewModel.selectedActivity = "All"
                                }

                                MapActivityButton(
                                    title: "Randonnée",
                                    isSelected: viewModel.selectedActivity == "Randonnée"
                                ) {
                                    viewModel.selectedActivity = "Randonnée"
                                }

                                MapActivityButton(
                                    title: "Vélo",
                                    isSelected: viewModel.selectedActivity == "Vélo"
                                ) {
                                    viewModel.selectedActivity = "Vélo"
                                }
                            }
                        }
                        .padding()
                        .background(AppColors.CardDark)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Date")
                                .font(.headline)
                                .foregroundColor(AppColors.TextPrimary)
                            
                            ForEach(MapViewModel.DateFilter.allCases, id: \.self) { filter in
                                Button {
                                    viewModel.selectedDateFilter = filter
                                } label: {
                                    HStack {
                                        Image(systemName: filter.icon)
                                            .foregroundColor(AppColors.GreenAccent)
                                        
                                        Text(filter.rawValue)
                                            .foregroundColor(AppColors.TextPrimary)
                                        
                                        Spacer()
                                        
                                        if viewModel.selectedDateFilter == filter {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(AppColors.GreenAccent)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        viewModel.selectedDateFilter == filter
                                        ? AppColors.GreenAccent.opacity(0.2)
                                        : AppColors.CardGlass
                                    )
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                        .background(AppColors.CardDark)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        if viewModel.activeFiltersCount > 0 {
                            Button {
                                viewModel.resetFilters()
                                Task {
                                    await viewModel.load()
                                }
                            } label: {
                                Text("Réinitialiser tous les filtres")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppColors.GreenAccent)
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Filtres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Appliquer") {
                        Task {
                            await viewModel.load()
                            dismiss()
                        }
                    }
                    .foregroundColor(AppColors.GreenAccent)
                    .bold()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct MapFilterButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: isSelected
                                           ? [AppColors.GreenAccent, AppColors.GreenDark]
                                           : [AppColors.CardGlass, AppColors.CardGlass.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(isSelected ? .black : AppColors.TextSecondary)
                .cornerRadius(12)
        }
    }
}

struct MapActivityButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if title == "Randonnée" {
                    Image(systemName: "figure.hiking")
                        .font(.system(size: 13, weight: .semibold))
                } else if title == "Vélo" {
                    Image(systemName: "bicycle")
                        .font(.system(size: 13, weight: .semibold))
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                }

                Text(title)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                (isSelected
                 ? AnyShapeStyle(LinearGradient(
                        gradient: Gradient(colors: [AppColors.GreenAccent, AppColors.GreenDark]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                 : AnyShapeStyle(AppColors.CardGlass))
            )
            .cornerRadius(12)
            .foregroundColor(isSelected ? .black : AppColors.TextSecondary)
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
            .preferredColorScheme(.dark)
    }
}
