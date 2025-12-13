//
//  FilterSheets.swift
//  VIBRA
//

import SwiftUI
import CoreLocation

// MARK: - Date Filter Sheet
struct DateFilterSheet: View {
    @ObservedObject var viewModel: HomeViewModel
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
                
                VStack(spacing: 20) {
                    ForEach(HomeViewModel.DateFilter.allCases, id: \.self) { filter in
                        Button {
                            viewModel.selectedDateFilter = filter
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: filter.icon)
                                    .font(.title3)
                                    .foregroundColor(AppColors.GreenAccent)
                                    .frame(width: 40)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(filter.rawValue)
                                        .font(.headline)
                                        .foregroundColor(AppColors.TextPrimary)
                                    
                                    Text(filterDescription(for: filter))
                                        .font(.caption)
                                        .foregroundColor(AppColors.TextSecondary)
                                }
                                
                                Spacer()
                                
                                if viewModel.selectedDateFilter == filter {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppColors.GreenAccent)
                                        .font(.title3)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AppColors.CardDark)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                viewModel.selectedDateFilter == filter
                                                ? AppColors.GreenAccent.opacity(0.5)
                                                : AppColors.BorderColor,
                                                lineWidth: viewModel.selectedDateFilter == filter ? 2 : 1
                                            )
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Filtrer par date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.GreenAccent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func filterDescription(for filter: HomeViewModel.DateFilter) -> String {
        switch filter {
        case .all:
            return "Toutes les sorties disponibles"
        case .today:
            return "Sorties prévues aujourd'hui"
        case .thisWeek:
            return "Sorties de cette semaine"
        case .thisMonth:
            return "Sorties de ce mois"
        case .upcoming:
            return "Toutes les sorties à venir"
        }
    }
}

// MARK: - Location Filter Sheet
struct LocationFilterSheet: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var locationManager: RideLocationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedRadius: Double
    
    init(viewModel: HomeViewModel, locationManager: RideLocationManager) {
        self.viewModel = viewModel
        self.locationManager = locationManager
        self._selectedRadius = State(initialValue: viewModel.searchRadius)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [AppColors.BackgroundGradientStart, AppColors.BackgroundGradientEnd]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(AppColors.GreenAccent)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ma position")
                                .font(.headline)
                                .foregroundColor(AppColors.TextPrimary)
                            
                            if let location = locationManager.location {
                                Text("📍 \(String(format: "%.4f", location.coordinate.latitude)), \(String(format: "%.4f", location.coordinate.longitude))")
                                    .font(.caption)
                                    .foregroundColor(AppColors.TextSecondary)
                            } else if locationManager.authorizationStatus == .denied {
                                Text("⚠️ Accès refusé - Activez dans Réglages")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            } else {
                                Text("🔍 Localisation en cours...")
                                    .font(.caption)
                                    .foregroundColor(AppColors.TextSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            locationManager.requestLocation()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(AppColors.GreenAccent)
                                .padding(8)
                                .background(AppColors.CardGlass)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(AppColors.CardDark)
                    .cornerRadius(16)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "scope")
                                .foregroundColor(AppColors.GreenAccent)
                            Text("Rayon de recherche")
                                .font(.headline)
                                .foregroundColor(AppColors.TextPrimary)
                        }
                        
                        HStack {
                            Text("\(Int(selectedRadius)) km")
                                .font(.title2.bold())
                                .foregroundColor(AppColors.GreenAccent)
                            Spacer()
                        }
                        
                        Slider(value: $selectedRadius, in: 5...200, step: 5)
                            .tint(AppColors.GreenAccent)
                        
                        HStack {
                            Text("5 km")
                                .font(.caption)
                                .foregroundColor(AppColors.TextSecondary)
                            Spacer()
                            Text("200 km")
                                .font(.caption)
                                .foregroundColor(AppColors.TextSecondary)
                        }
                    }
                    .padding()
                    .background(AppColors.CardDark)
                    .cornerRadius(16)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Raccourcis")
                            .font(.headline)
                            .foregroundColor(AppColors.TextPrimary)
                        
                        HStack(spacing: 12) {
                            QuickRadiusButton(radius: 10, selected: selectedRadius, action: { selectedRadius = $0 })
                            QuickRadiusButton(radius: 25, selected: selectedRadius, action: { selectedRadius = $0 })
                            QuickRadiusButton(radius: 50, selected: selectedRadius, action: { selectedRadius = $0 })
                            QuickRadiusButton(radius: 100, selected: selectedRadius, action: { selectedRadius = $0 })
                        }
                    }
                    .padding()
                    .background(AppColors.CardDark)
                    .cornerRadius(16)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button {
                            viewModel.userLocation = nil
                            viewModel.searchRadius = 50
                            dismiss()
                        } label: {
                            Text("Réinitialiser")
                                .font(.headline)
                                .foregroundColor(AppColors.TextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.CardGlass)
                                .cornerRadius(16)
                        }
                        
                        Button {
                            viewModel.searchRadius = selectedRadius
                            if locationManager.location != nil {
                                viewModel.userLocation = locationManager.location?.coordinate
                            }
                            dismiss()
                        } label: {
                            Text("Appliquer")
                                .font(.headline.bold())
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [AppColors.GreenAccent, AppColors.GreenDark],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: AppColors.GlowGreen.opacity(0.5), radius: 10)
                        }
                        .disabled(locationManager.location == nil)
                        .opacity(locationManager.location == nil ? 0.5 : 1.0)
                    }
                }
                .padding()
            }
            .navigationTitle("Filtrer par localisation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.GreenAccent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct QuickRadiusButton: View {
    let radius: Double
    let selected: Double
    let action: (Double) -> Void
    
    var body: some View {
        Button {
            action(radius)
        } label: {
            Text("\(Int(radius))km")
                .font(.caption.bold())
                .foregroundColor(selected == radius ? .black : AppColors.TextSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    selected == radius
                    ? AnyShapeStyle(LinearGradient(
                        colors: [AppColors.GreenAccent, AppColors.GreenDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    : AnyShapeStyle(AppColors.CardGlass)
                )
                .cornerRadius(12)
        }
    }
}

// MARK: - Complete Filters Sheet
struct FiltersSheetView: View {
    @ObservedObject var viewModel: HomeViewModel
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
                    VStack(spacing: 24) {
                        if viewModel.activeFiltersCount > 0 {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("\(viewModel.activeFiltersCount) filtre(s) actif(s)")
                                        .font(.headline)
                                        .foregroundColor(AppColors.GreenAccent)
                                    
                                    Spacer()
                                    
                                    Button {
                                        viewModel.resetFilters()
                                    } label: {
                                        Text("Tout réinitialiser")
                                            .font(.caption.bold())
                                            .foregroundColor(AppColors.TextSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(AppColors.CardGlass)
                                            .cornerRadius(8)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    if !viewModel.searchText.isEmpty {
                                        RemovableFilterChip(text: "🔍 \(viewModel.searchText)") {
                                            viewModel.searchText = ""
                                        }
                                    }
                                    if viewModel.selectedActivity != "All" {
                                        RemovableFilterChip(text: "🚴 \(viewModel.selectedActivity)") {
                                            viewModel.selectedActivity = "All"
                                        }
                                    }
                                    if viewModel.selectedDateFilter != .all {
                                        RemovableFilterChip(text: "📅 \(viewModel.selectedDateFilter.rawValue)") {
                                            viewModel.selectedDateFilter = .all
                                        }
                                    }
                                    if viewModel.userLocation != nil {
                                        RemovableFilterChip(text: "📍 À proximité (\(Int(viewModel.searchRadius))km)") {
                                            viewModel.userLocation = nil
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(AppColors.CardDark)
                            .cornerRadius(16)
                        }
                        
                        HStack(spacing: 16) {
                            StatCard(
                                icon: "list.bullet",
                                value: "\(viewModel.items.count)",
                                label: "Total"
                            )
                            StatCard(
                                icon: "checkmark.circle",
                                value: "\(viewModel.filteredItems.count)",
                                label: "Filtrées"
                            )
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Filtres avancés")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.GreenAccent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct RemovableFilterChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Text(text)
                .font(.caption)
                .foregroundColor(AppColors.TextPrimary)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(AppColors.TextSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppColors.CardGlass)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.GreenAccent.opacity(0.3), lineWidth: 1)
        )
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppColors.GreenAccent)
            
            Text(value)
                .font(.title.bold())
                .foregroundColor(AppColors.TextPrimary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(AppColors.TextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppColors.CardDark)
        .cornerRadius(16)
    }
}
