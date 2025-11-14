//
//  HomeView.swift
//  VIBRA
//
//  Created by mac book pro on 11/7/25.
//
// HomeView.swift
import SwiftUI

struct HomeView: View {
    @State private var searchText = ""
    @State private var selectedTab = "Explore"
    @State private var selectedActivity = "All" // Randonnée ou Vélo

    var body: some View {
        ZStack {
            // 🌌 Arrière-plan sombre et flou
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.black.opacity(0.9)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // 🔍 Barre de recherche avec effet verre
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.8))
                    TextField("Search", text: $searchText)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "mic.fill")
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .white.opacity(0.1), radius: 8)
                .padding(.horizontal)

                // 🚴‍♂️ Filtre activité (Randonnée / Vélo)
                HStack(spacing: 12) {
                    ActivityFilterButton(title: "All", isSelected: selectedActivity == "All") {
                        selectedActivity = "All"
                    }
                    ActivityFilterButton(title: "Randonnée", isSelected: selectedActivity == "Randonnée") {
                        selectedActivity = "Randonnée"
                    }
                    ActivityFilterButton(title: "Vélo", isSelected: selectedActivity == "Vélo") {
                        selectedActivity = "Vélo"
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // 🔘 Boutons principaux
                HStack(spacing: 10) {
                    FilterButton(title: "Followers", isSelected: selectedTab == "Followers") {
                        selectedTab = "Followers"
                    }
                    FilterButton(title: "Recommendation", isSelected: selectedTab == "Recommendation") {
                        selectedTab = "Recommendation"
                    }
                    FilterButton(title: "Explore", isSelected: selectedTab == "Explore") {
                        selectedTab = "Explore"
                    }
                }
                .padding(.horizontal)

                // 📋 Liste des sorties
                ScrollView {
                    VStack(spacing: 20) {
                        if selectedActivity == "All" || selectedActivity == "Vélo" {
                            RideCard(
                                imageName: "velo",
                                title: "Morning Ride",
                                location: "La Marsa",
                                time: "8:30 AM",
                                level: "Medium",
                                distance: "25 km"
                            )
                        }

                        if selectedActivity == "All" || selectedActivity == "Randonnée" {
                            RideCard(
                                imageName: "randonnee",
                                title: "Weekend Mountain",
                                location: "Mountain",
                                time: "8:30 AM",
                                level: "Medium",
                                distance: "25 km"
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 90) // espace pour tabbar
                }
            }
            .padding(.top, 10)
        }
        .navigationBarBackButtonHidden(true) // ❌ supprime la flèche de retour
        .navigationBarHidden(true) // ❌ cache complètement la barre
        .preferredColorScheme(.dark)
    }
}

// MARK: - Carte de sortie
struct RideCard: View {
    var imageName: String
    var title: String
    var location: String
    var time: String
    var level: String
    var distance: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .clipped()
                .cornerRadius(18)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    HStack(spacing: 5) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("at \(location)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.7))
            }

            HStack(spacing: 16) {
                Label(time, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(level)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.85))
                    .cornerRadius(8)
                Text(distance)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .white.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Boutons
struct FilterButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.green.opacity(0.8) : Color.white.opacity(0.08))
                .cornerRadius(10)
                .foregroundColor(isSelected ? .white : .gray)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

struct ActivityFilterButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.green.opacity(0.8) : Color.white.opacity(0.08))
                .cornerRadius(10)
                .foregroundColor(isSelected ? .white : .gray)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView() // ✅ TabBar affichée correctement
    }
}
