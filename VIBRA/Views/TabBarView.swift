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
                // 🌌 Fond global cohérent avec le reste de l'app
                LinearGradient(
                    gradient: Gradient(colors: [AppColors.BackgroundGradientStart, AppColors.BackgroundGradientEnd]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // MARK: - Contenu principal (TabView)
                VStack(spacing: 0) {
                    Spacer(minLength: 70) // espace pour la top bar

                    TabView {
                        HomeView()
                            .tabItem {
                                Image(systemName: "house.fill")
                                Text("Home")
                            }

                        MapView()
                            .tabItem {
                                Image(systemName: "map.fill")
                                Text("Map")
                            }

                        Text("Community View")
                            .tabItem {
                                Image(systemName: "person.2.fill")
                                Text("Community")
                            }

                        ProfileView()
                            .tabItem {
                                Image(systemName: "person.crop.circle.fill")
                                Text("Profile")
                            }

                        CreateSortieView()
                            .tabItem {
                                Image(systemName: "plus.circle.fill")
                                Text("Add")
                            }
                    }
                    .tint(AppColors.GreenAccent)
                    .background(Color.clear.ignoresSafeArea())
                }

                // MARK: - Top Bar VIBRA style
                VStack(spacing: 0) {
                    ZStack {
                        HStack {
                            // Logo / Titre
                            Text("VIBRA")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.TextPrimary)
                                .shadow(color: AppColors.GlowGreen.opacity(0.5), radius: 8, x: 0, y: 4)

                            Spacer()

                            // Bouton flèche
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showOptions.toggle()
                                }
                            }) {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(AppColors.TextPrimary)
                                    .rotationEffect(.degrees(showOptions ? 180 : 0))
                                    .padding(8)
                                    .background(AppColors.CardGlass)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(AppColors.DividerColor, lineWidth: 0.8)
                                    )
                                    .shadow(color: AppColors.ShadowColor.opacity(0.7), radius: 6, x: 0, y: 3)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [AppColors.CardDark.opacity(0.95), AppColors.CardDark.opacity(0.8)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .blur(radius: 0)
                    )
                    .overlay(
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundColor(AppColors.DividerColor),
                        alignment: .bottom
                    )
                    .shadow(color: AppColors.ShadowColor.opacity(0.9), radius: 8, x: 0, y: 4)

                    // MARK: - Menu déroulant (glassmorphism)
                    if showOptions {
                        VStack(alignment: .leading, spacing: 10) {
                            MenuItemView(icon: "bookmark", label: "Saved")
                            MenuItemView(icon: "questionmark.circle", label: "Help Center")
                            MenuItemView(icon: "gearshape", label: "Settings")

                            Button {
                                showLogoutAlert = true
                            } label: {
                                MenuItemView(icon: "arrowshape.turn.up.left", label: "Logout", isDestructive: true)
                            }
                        }
                        .padding(10)
                        .background(AppColors.CardDark.opacity(0.85))
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.BorderColor, lineWidth: 0.6)
                        )
                        .shadow(color: AppColors.ShadowColor.opacity(0.9), radius: 10, x: 0, y: 6)
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
            NavigationLink(
                destination: LoginView()
                    .navigationBarBackButtonHidden(true)
                    .navigationBarHidden(true),
                isActive: $isLoggedOut
            ) {
                EmptyView()
            }
            .opacity(0)
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Élément du menu
struct MenuItemView: View {
    var icon: String
    var label: String
    var isDestructive: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(isDestructive ? .red : AppColors.GreenAccent)
                .frame(width: 24)

            Text(label)
                .foregroundColor(isDestructive ? .red : AppColors.TextPrimary)
                .font(.system(size: 15, weight: .medium, design: .rounded))

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.CardGlass)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.DividerColor, lineWidth: 0.6)
        )
        .shadow(color: AppColors.ShadowColor.opacity(0.6), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Preview
#Preview {
    TabBarView()
        .preferredColorScheme(.dark)
}
