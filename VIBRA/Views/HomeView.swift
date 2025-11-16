//
//  HomeView.swift
//  VIBRA
//
//  Created by mac book pro on 11/7/25.
//
// HomeView.swift
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var searchText = ""
    @State private var selectedTab = "Explore"
    @State private var selectedActivity = "All"

    var body: some View {
        NavigationStack { // Added navigation container
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
                        ActivityFilterButton(title: "All", isSelected: selectedActivity == "All") { selectedActivity = "All" }
                        ActivityFilterButton(title: "Randonnée", isSelected: selectedActivity == "Randonnée") { selectedActivity = "Randonnée" }
                        ActivityFilterButton(title: "Vélo", isSelected: selectedActivity == "Vélo") { selectedActivity = "Vélo" }
                        Spacer()
                    }
                    .padding(.horizontal)

                    // 📝 Boutons principaux
                    HStack(spacing: 10) {
                        FilterButton(title: "Followers", isSelected: selectedTab == "Followers") { selectedTab = "Followers" }
                        FilterButton(title: "Recommendation", isSelected: selectedTab == "Recommendation") { selectedTab = "Recommendation" }
                        FilterButton(title: "Explore", isSelected: selectedTab == "Explore") { selectedTab = "Explore" }
                    }
                    .padding(.horizontal)

                    // 📋 Liste des sorties
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            if viewModel.isLoading {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).padding()
                                Text("Chargement des sorties...")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.caption)
                            } else if let error = viewModel.errorMessage {
                                VStack(spacing: 10) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.red)
                                    Text("Erreur de chargement")
                                        .foregroundColor(.red)
                                        .font(.headline)
                                    Text(error)
                                        .foregroundColor(.red)
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                    Button("Réessayer") { Task { await viewModel.load() } }
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                .padding()
                            } else if viewModel.items.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "tray.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                    Text("Aucune sortie disponible")
                                        .foregroundColor(.gray)
                                        .font(.headline)
                                    Text("Les sorties s'afficheront ici")
                                        .foregroundColor(.gray.opacity(0.7))
                                        .font(.caption)
                                }
                                .padding()
                            } else {
                                Text("✅ \(viewModel.items.count) sortie(s) chargée(s)")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                    .padding(.bottom, 5)
                                ForEach(viewModel.items, id: \.id) { item in
                                    NavigationLink(destination: SortieDetailView(ride: item.ride, creator: item.creator)) {
                                        RideCardView(item: item)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 90) // espace pour tabbar
                    }
                }
                .padding(.top, 10)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
            .task {
                print("🚀 HomeView: Appearing, about to load data...")
                await viewModel.load()
                print("🏁 HomeView: Load completed. Items count: \(viewModel.items.count)")
            }
        }
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
