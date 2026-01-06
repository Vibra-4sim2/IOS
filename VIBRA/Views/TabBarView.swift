import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var ratingPromptViewModel: RatingPromptViewModel
    @StateObject private var notificationViewModel = NotificationViewModel()
    @State private var showOptions = false
    @State private var showLogoutAlert = false
    @State private var isLoggedOut = false

    // For opening the creation (floating button)
    @State private var showCreateModal: Bool = false

    // Manual management of the selected tab
    @State private var selectedTab: Int = 0
    @State private var lastValidTab: Int = 0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {

                // MARK: - Main content (TabView WITH INACTIVE EMPTY SLOT)
                VStack(spacing: 0) {
                    Spacer(minLength: 60) // space for the top bar

                    TabView(selection: $selectedTab) {
                        HomeView()
                            .tabItem {
                                Image(systemName: "house.fill")
                                Text("Home")
                            }
                            .tag(0)

                        MessagesHubView()
                            .tabItem {
                                Image(systemName: "message.fill")
                                Text("Messages")
                            }
                            .tag(1)

                        // EMPTY SLOT in the middle: takes up space, but we block via `onChange`
                        Color.clear
                            .tabItem {
                                Text(" ") // minimum to keep the location
                            }
                            .tag(2)

                        FeedView(onCreatePost: {}, onOpenPost: { _ in })
                            .tabItem {
                                Image(systemName: "person.2.fill")
                                Text("Community")
                            }
                            .tag(3)

                        ProfileView()
                            .tabItem {
                                Image(systemName: "person.crop.circle.fill")
                                Text("Profile")
                            }
                            .tag(4)
                    }
                    .onChange(of: selectedTab) { newValue in
                        // If trying to select the empty slot (2), revert to the last valid tab
                        if newValue == 2 {
                            selectedTab = lastValidTab
                        } else {
                            lastValidTab = newValue
                        }
                    }
                    .accentColor(AppColors.GreenAccent)
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [AppColors.BackgroundGradientStart, AppColors.BackgroundGradientEnd]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                )

                // MARK: - Top Bar
                VStack(spacing: 0) {
                    HStack {
                        // Logo and name VIBRA - ON THE LEFT
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

                        // Map - At the top (replaces Messages)
                        NavigationLink {
                            MapView(showBackButton: true)
                        } label: {
                            Image(systemName: "map.fill")
                                .font(.system(size: 22))
                                .foregroundColor(AppColors.GreenAccent)
                                .padding(.horizontal, 4)
                        }

                        // Notification Bell with Badge
                        ZStack {
                            NavigationLink {
                                NotificationsView()
                            } label: {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                            }
                            
                            if notificationViewModel.hasUnreadNotifications {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                                    .offset(x: 10, y: -10)
                            }
                        }
                        
                        // Menu button (3 bars) - RIGHT
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
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    .background(
                        AppColors.CardDark.opacity(0.95)
                    )

                    if showOptions {
                        VStack(alignment: .leading, spacing: 10) {
                            // Requests (was Mes Sorties)
                            NavigationLink {
                                MyRidesHomeView(showBackButton: true)
                            } label: {
                                MenuItemView(icon: "tray.full", label: "Requests")
                            }
                            
                            NavigationLink {
                                SavedRidesView()
                            } label: {
                                MenuItemView(icon: "bookmark", label: "Saved")
                            }
                            
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

                // MARK: - Large green floating button (Add) CENTERED, LARGER, LOWER
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showCreateModal = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))   // larger
                                .foregroundColor(.black)
                                .padding(18)                               // larger
                                .background(AppColors.GreenAccent)
                                .clipShape(Circle())
                                .shadow(color: AppColors.ShadowColor.opacity(0.85),
                                        radius: 10, x: 0, y: 4)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 12) // very low, close to the TabBar
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
                        print("❌ Error logout: \(error)")
                    }
                }
            }, message: {
                Text("Are you sure you want to logout?")
            })

            // MARK: - Navigation to Login after logout
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

            // MARK: - Full screen modal for CreateSortie (linked to the floating button)
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
            
            // Setup notification tap handler
            setupNotificationTapHandler()
        }
    }
    
    // MARK: - Notification Tap Handler
    
    private func setupNotificationTapHandler() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("HandleNotificationTap"),
            object: nil,
            queue: .main
        ) { [self] notification in
            guard let userInfo = notification.userInfo,
                  let type = userInfo["type"] as? String else {
                return
            }
            
            print("🔔 Handling notification tap: \(type)")
            
            // Navigate based on notification type
            switch type {
            case "private_message":
                selectedTab = 0
            case "group_message":
                selectedTab = 0
            case "new_participant", "sortie_update", "sortie_reminder":
                selectedTab = 4
            default:
                break
            }
        }
    }
}

// MARK: - Menu item element
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
