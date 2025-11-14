//
//  TabBarView.swift
//  VIBRA
//
//  Created by mac book pro on 11/7/25.
//

import SwiftUI

struct TabBarView: View {
    @State private var showOptions = false
    @State private var showLogoutAlert = false
    @State private var isLoggedOut = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // MARK: - Contenu principal (TabView)
                VStack(spacing: 0) {
                    Spacer(minLength: 60) // espace pour la top bar
                    
                    TabView {
                        HomeView()
                            .tabItem {
                                Image(systemName: "house")
                                Text("Home")
                            }

                        MapView()
                            .tabItem {
                                Image(systemName: "map")
                                Text("Map")
                            }

                        Text("Community View")
                            .tabItem {
                                Image(systemName: "person.2")
                                Text("Community")
                            }

                        ProfileView()
                            .tabItem {
                                Image(systemName: "person")
                                Text("Profile")
                            }

                        Text("Add View")
                            .tabItem {
                                Image(systemName: "plus")
                                Text("Add")
                            }
                    }
                    .accentColor(.green)
                    .background(Color.black.ignoresSafeArea())
                }
                .background(Color.black.ignoresSafeArea())

                // MARK: - Top Bar
                VStack(spacing: 0) {
                    HStack {
                        Text("VIBRA")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)

                        Spacer()

                        // Bouton flèche
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showOptions.toggle()
                            }
                        }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(showOptions ? 180 : 0))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .background(Color.black.opacity(0.9))
                    .shadow(radius: 5)

                    // MARK: - Menu déroulant (affiché au-dessus du TabView)
                    if showOptions {
                        VStack(alignment: .leading, spacing: 10) {
                            //MenuItemView(icon: "person", label: "Profil")
                            MenuItemView(icon: "bookmark", label: "Saved")
                            MenuItemView(icon: "questionmark.circle", label: "Help Center")
                            MenuItemView(icon: "gearshape", label: "Settings")
                            
                            Button {
                                showLogoutAlert = true
                            } label: {
                                MenuItemView(icon: "arrowshape.turn.up.left", label: "Logout")
                            }
                        }
                        .padding(10)
                        .background(Color(.systemGray6).opacity(0.15))
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                        .shadow(radius: 6)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Spacer()
                }
            }
            .alert("Logout", isPresented: $showLogoutAlert, actions: {
                Button("Cancel", role: .cancel) {}
                Button("Confirm", role: .destructive) {
                    do {
                        try KeychainManager.shared.deleteJWT()
                        isLoggedOut = true
                    } catch {
                        print("❌ Erreur logout: \(error)")
                    }
                }
            }, message: {
                Text("Are you sure you want to logout?")
            })
            // MARK: - Navigation vers Login après logout
            NavigationLink(destination: LoginView()
                .navigationBarBackButtonHidden(true) // ✅ cache la flèche
                .navigationBarHidden(true)           // (optionnel) cache toute la barre
            , isActive: $isLoggedOut) {
                EmptyView()
            }
            .opacity(0)
        }
    }
}

// MARK: - Élément du menu
struct MenuItemView: View {
    var icon: String
    var label: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 24)

            Text(label)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.25))
        .cornerRadius(10)
    }
}

// MARK: - Preview
#Preview {
    TabBarView()
}
