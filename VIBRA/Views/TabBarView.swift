//
//  TabBarView.swift
//  VIBRA
//
//  Created by mac book pro on 11/7/25.
//  Version corrigée : custom tab bar fixe, bouton central réduit et navigation propre.
//

import SwiftUI

struct TabBarView: View {
    @State private var showOptions = false
    @State private var showLogoutAlert = false
    @State private var isLoggedOut = false

    // 0: Home, 1: Map, 2: Feed, 3: MyRides
    @State private var selectedTab: Int = 0

    // Modal pour la création (bouton central)
    @State private var showCreateModal: Bool = false

    // safe area bottom (fallback au cas où)
    private var bottomSafeAreaInset: CGFloat {
        let inset = UIApplication.shared.windows.first?.safeAreaInsets.bottom
        return inset ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background
                LinearGradient(
                    gradient: Gradient(colors: [AppColors.BackgroundGradientStart, AppColors.BackgroundGradientEnd]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // MARK: - Main tab content
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tag(0)
                        .ignoresSafeArea(edges: .bottom)

                    MapView()
                        .tag(1)
                        .ignoresSafeArea(edges: .bottom)

                    FeedView(onCreatePost: {}, onOpenPost: { _ in })
                        .tag(2)
                        .ignoresSafeArea(edges: .bottom)

                    MyRidesHomeView()
                        .tag(3)
                        .ignoresSafeArea(edges: .bottom)
                }
                .tint(AppColors.GreenAccent)
                // give space for the custom bar so content isn't hidden behind it
                .padding(.bottom, 90)

                // MARK: - Custom bottom tab bar (overlay)
                VStack {
                    Spacer()

                    HStack {
                        Spacer()

                        // Tab items (left)
                        tabItem(icon: "house.fill", index: 0)
                        Spacer(minLength: 20)
                        tabItem(icon: "map.fill", index: 1)

                        Spacer(minLength: 32) // espace pour le bouton central

                        // Tab items (right)
                        tabItem(icon: "person.2.fill", index: 2)
                        Spacer(minLength: 20)
                        tabItem(icon: "person.text.rectangle", index: 3)

                        Spacer()
                    }
                    .padding(.horizontal, 26)
                    .padding(.vertical, 12)
                    .background(
                        // solid-ish capsule so it doesn't look transparent or sit above content
                        Capsule()
                            .fill(AppColors.CardDark.opacity(0.95))
                    )
                    .overlay(
                        Capsule()
                            .stroke(AppColors.DividerColor, lineWidth: 0.6)
                    )
                    .shadow(color: AppColors.ShadowColor.opacity(0.85), radius: 10, x: 0, y: 6)
                    .padding(.horizontal, 14)
                    .padding(.bottom, max(12, bottomSafeAreaInset)) // respecte la safe area

                    // Centre button sits visually above the capsule (overlay)
                    .overlay(
                        Button(action: {
                            // action propre : ouvrir modal de création
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                                showCreateModal = true
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.GreenAccent)
                                    .frame(width: 58, height: 58) // taille réduite (plus correcte)
                                    .shadow(color: AppColors.GlowGreen.opacity(0.8), radius: 16, x: 0, y: 6)

                                Image(systemName: "plus")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                        // place it centered horizontally and slightly above the bar (pas trop haut)
                        .offset(y: -32)
                        , alignment: .center
                    )
                } // VStack
                .edgesIgnoringSafeArea(.bottom)

                // MARK: - Top Bar (logo / menu / profile)
                VStack(spacing: 0) {
                    HStack {
                        Text("VIBRA")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.TextPrimary)
                            .shadow(color: AppColors.GlowGreen.opacity(0.5), radius: 8, x: 0, y: 4)

                        Spacer()

                        // Menu déroulant
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
                        .padding(.trailing, 8)

                        // Profile icon inside top bar (à côté du menu)
                        NavigationLink {
                            ProfileView()
                        } label: {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 28))
                                .foregroundColor(AppColors.GreenAccent)
                                .shadow(color: AppColors.GlowGreen.opacity(0.7), radius: 10)
                                .padding(.leading, 4)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [AppColors.CardDark.opacity(0.95), AppColors.CardDark.opacity(0.85)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundColor(AppColors.DividerColor),
                        alignment: .bottom
                    )
                    .shadow(color: AppColors.ShadowColor.opacity(0.9), radius: 8, x: 0, y: 4)

                    // Menu déroulant si activé
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
                        .background(AppColors.CardDark.opacity(0.9))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.BorderColor, lineWidth: 0.6))
                        .shadow(color: AppColors.ShadowColor.opacity(0.9), radius: 10, x: 0, y: 6)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Spacer() // push topbar up
                } // VStack topbar
            } // ZStack
            // Logout alert + navigation
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

            // MARK: - Full screen modal for CreateSortie (activated by center button)
            .fullScreenCover(isPresented: $showCreateModal) {
                NavigationStack {
                    CreateSortieView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") {
                                    showCreateModal = false
                                }
                            }
                        }
                        .preferredColorScheme(.dark)
                }
            }
        } // NavigationStack
    }

    // MARK: - Tab item builder
    func tabItem(icon: String, index: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                selectedTab = index
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(selectedTab == index ? AppColors.GreenAccent : AppColors.TextSecondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
    }
}

// MenuItemView (inchangé)
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

#Preview {
    TabBarView()
        .preferredColorScheme(.dark)
}
