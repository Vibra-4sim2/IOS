//
//  TabBarView.swift
//  VIBRA
//
//  Version : barre corrigée + bouton central cohérent + bouton chat en haut
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

    private var bottomSafeAreaInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?
            .safeAreaInsets.bottom ?? 0
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
                // on n’utilise plus un gros padding bas qui donnait l’effet "flottant"
                //.padding(.bottom, 90)

                // MARK: - Custom bottom tab bar + center button
                VStack {
                    Spacer()

                    ZStack(alignment: .bottom) {
                        // Barre de navigation inférieure
                        HStack {
                            // Côté gauche
                            tabItem(icon: "house.fill", index: 0)
                            Spacer()
                            tabItem(icon: "map.fill", index: 1)

                            Spacer(minLength: 60) // espace pour le bouton central

                            // Côté droit
                            tabItem(icon: "person.2.fill", index: 2)
                            Spacer()
                            tabItem(icon: "person.text.rectangle", index: 3)
                        }
                        .padding(.horizontal, 26)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .fill(AppColors.CardDark.opacity(0.98))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .stroke(AppColors.DividerColor, lineWidth: 0.6)
                        )
                        .shadow(color: AppColors.ShadowColor.opacity(0.8), radius: 10, x: 0, y: 6)
                        .padding(.horizontal, 14)
                        .padding(.bottom, max(8, bottomSafeAreaInset)) // bien calée au bas

                        // Bouton central par-dessus la barre
                        Button(action: {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                                showCreateModal = true
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.GreenAccent)
                                    .frame(width: 64, height: 64)
                                    .shadow(color: AppColors.GlowGreen.opacity(0.9), radius: 18, x: 0, y: 8)

                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                        .offset(y: -26) // remonte légèrement le bouton au-dessus de la barre
                    }
                    .ignoresSafeArea(edges: .bottom)
                }

                // MARK: - Top Bar (logo / menu / chat / profile)
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

                        // Bouton Chat à côté du profil
                        NavigationLink {
                            ChatsListView()
                        } label: {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppColors.GreenAccent)
                                .shadow(color: AppColors.GlowGreen.opacity(0.7), radius: 10)
                                .padding(.horizontal, 6)
                        }

                        // Profile icon
                        NavigationLink {
                            ProfileView()
                        } label: {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 28))
                                .foregroundColor(AppColors.GreenAccent)
                                .shadow(color: AppColors.GlowGreen.opacity(0.7), radius: 10)
                                .padding(.leading, 2)
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

                    Spacer()
                }
            }
            // MARK: - Logout alert + navigation
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

            // MARK: - Full screen modal pour CreateSortie (bouton central)
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
        }
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

// Preview demandé pour la liste des chats
#Preview("Chats") {
    ChatsListView()
        .preferredColorScheme(.dark)
}
