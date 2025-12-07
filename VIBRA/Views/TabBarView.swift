import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var ratingPromptViewModel: RatingPromptViewModel
    @State private var showOptions = false
    @State private var showLogoutAlert = false
    @State private var isLoggedOut = false

    // Pour ouvrir la création (bouton flottant)
    @State private var showCreateModal: Bool = false

    // Gestion manuelle de l'onglet sélectionné
    @State private var selectedTab: Int = 0
    @State private var lastValidTab: Int = 0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {

                // MARK: - Contenu principal (TabView AVEC SLOT VIDE INACTIF)
                VStack(spacing: 0) {
                    Spacer(minLength: 60) // espace pour la top bar

                    TabView(selection: $selectedTab) {
                        HomeView()
                            .tabItem {
                                Image(systemName: "house.fill")
                                Text("Home")
                            }
                            .tag(0)

                        MapView()
                            .tabItem {
                                Image(systemName: "map.fill")
                                Text("Map")
                            }
                            .tag(1)

                        // SLOT VIDE au milieu : occupe la place, mais qu'on bloque via `onChange`
                        Color.clear
                            .tabItem {
                                Text(" ") // minimum pour garder l'emplacement
                            }
                            .tag(2)

                        FeedView(onCreatePost: {}, onOpenPost: { _ in })
                            .tabItem {
                                Image(systemName: "person.2.fill")
                                Text("Community")
                            }
                            .tag(3)

                        MyRidesHomeView()
                            .tabItem {
                                Image(systemName: "person.text.rectangle")
                                Text("My Rides")
                            }
                            .tag(4)
                    }
                    .onChange(of: selectedTab) { newValue in
                        // Si on essaie de sélectionner le slot vide (2), on revient au dernier vrai onglet
                        if newValue == 2 {
                            selectedTab = lastValidTab
                        } else {
                            lastValidTab = newValue
                        }
                    }
                    .accentColor(AppColors.GreenAccent)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [AppColors.BackgroundGradientStart, AppColors.BackgroundGradientEnd]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()
                    )
                }

                // MARK: - Top Bar
                VStack(spacing: 0) {
                    HStack {
                        Image("vibra_logo_white")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                        Text("VIBRA")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.TextPrimary)
                            .shadow(color: AppColors.GlowGreen.opacity(0.5), radius: 8, x: 0, y: 4)

                        Spacer()

                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showOptions.toggle()
                            }
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(AppColors.CardGlass)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(AppColors.DividerColor, lineWidth: 0.8)
                                )
                                .shadow(color: AppColors.ShadowColor.opacity(0.7), radius: 6, x: 0, y: 3)
                        }

                        NavigationLink {
                            ChatsListView()
                        } label: {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                        }

                        NavigationLink {
                            ProfileView()
                        } label: {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
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

                // MARK: - Bouton flottant vert (Add) CENTRÉ, PLUS GRAND, PLUS BAS
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showCreateModal = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))   // plus grand
                                .foregroundColor(.black)
                                .padding(18)                               // plus grand
                                .background(AppColors.GreenAccent)
                                .clipShape(Circle())
                                .shadow(color: AppColors.ShadowColor.opacity(0.85),
                                        radius: 10, x: 0, y: 4)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 12) // très bas, proche de la TabBar
                }

                // MARK: - Rating popup overlay on top of everything
                if ratingPromptViewModel.isPresenting {
                    SortieRatingPromptView(viewModel: ratingPromptViewModel)
                }
            }
            // MARK: - Alert Logout
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

            // MARK: - Full screen modal pour CreateSortie (lié au bouton flottant)
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
        .onAppear {
            print("[RatingPrompt] TabBarView appeared → checking eligibility")
            ratingPromptViewModel.onSceneBecameActive()
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

#Preview {
    TabBarView()
        .preferredColorScheme(.dark)
}
