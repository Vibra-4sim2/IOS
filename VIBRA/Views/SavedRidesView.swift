//
//  SavedRidesView.swift
//  VIBRA
//
//  View displaying saved rides for offline access
//

import SwiftUI

struct SavedRidesView: View {
    @State private var savedRides: [RideWithCreator] = []
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [AppColors.BackgroundGradientStart, AppColors.BackgroundGradientEnd]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.GreenAccent))
                        .padding()
                } else if savedRides.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(savedRides, id: \.ride.id) { item in
                                NavigationLink(destination: SortieDetailView(ride: item.ride, creator: item.creator)) {
                                    SavedRideCard(item: item) {
                                        removeRide(item)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                    }
                }
            }
        }
        .navigationTitle("Saved Rides")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                    }
                    .foregroundColor(AppColors.GreenAccent)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if !savedRides.isEmpty {
                    Button {
                        clearAllSaved()
                    } label: {
                        Text("Clear All")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .onAppear {
            loadSavedRides()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "bookmark.slash")
                .font(.system(size: 60))
                .foregroundColor(AppColors.TextTertiary)
            
            Text("No Saved Rides")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.TextPrimary)
            
            Text("Save rides to view them offline.\nTap the bookmark icon on any ride card.")
                .font(.system(size: 15))
                .foregroundColor(AppColors.TextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Actions
    
    private func loadSavedRides() {
        isLoading = true
        savedRides = SavedRidesManager.shared.getSavedRidesWithCreators()
        isLoading = false
    }
    
    private func removeRide(_ item: RideWithCreator) {
        guard let rideId = item.ride.id else { return }
        SavedRidesManager.shared.removeSavedRide(rideId)
        savedRides.removeAll { $0.ride.id == rideId }
    }
    
    private func clearAllSaved() {
        SavedRidesManager.shared.clearAllSaved()
        savedRides = []
    }
}

// MARK: - Saved Ride Card

struct SavedRideCard: View {
    let item: RideWithCreator
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            RideCardView(item: item)
            
            // Remove button
            Button {
                onRemove()
            } label: {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.GreenAccent)
                    .padding(10)
                    .background(AppColors.CardDark.opacity(0.9))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .padding(12)
        }
    }
}

#Preview {
    NavigationStack {
        SavedRidesView()
    }
    .preferredColorScheme(.dark)
}
