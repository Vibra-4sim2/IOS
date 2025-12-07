//
//  PreferencesView.swift
//  VIBRA
//
import SwiftUI

struct PreferencesView: View {
    @StateObject private var viewModel = PreferencesViewModel()
    @State private var currentPage = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Arrière-plan dégradé
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColors.BackgroundGradientStart,
                        AppColors.BackgroundGradientEnd
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        Spacer()
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.GreenAccent))
                                .scaleEffect(1.5)
                            Text("Loading your preferences...")
                                .font(.subheadline)
                                .foregroundColor(AppColors.TextSecondary)
                        }
                        .padding()
                        Spacer()
                    } else {
                        // Indicateur de page personnalisé
                        HStack(spacing: 8) {
                            ForEach(0..<3) { index in
                                Capsule()
                                    .fill(currentPage == index ? AppColors.GreenAccent : AppColors.CardGlass)
                                    .frame(width: currentPage == index ? 32 : 8, height: 8)
                                    .animation(.spring(response: 0.3), value: currentPage)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                        
                        // Titre de la page actuelle
                        Text(pageTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.TextPrimary)
                            .padding(.bottom, 8)
                        
                        // Contenu des pages
                        TabView(selection: $currentPage) {
                            CyclingView(preferences: $viewModel.preferences)
                                .tag(0)
                            HikingView(preferences: $viewModel.preferences)
                                .tag(1)
                            CampingView(preferences: $viewModel.preferences)
                                .tag(2)
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .frame(maxHeight: .infinity)
                        
                        // Boutons de navigation
                        HStack(spacing: 16) {
                            if currentPage > 0 {
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        currentPage -= 1
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "chevron.left")
                                        Text("Back")
                                    }
                                    .font(.headline)
                                    .foregroundColor(AppColors.TextPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(AppColors.CardDark)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppColors.BorderColor, lineWidth: 1)
                                    )
                                    .cornerRadius(12)
                                }
                            }
                            
                            Button(action: {
                                Task {
                                    if currentPage < 2 {
                                        withAnimation(.spring(response: 0.3)) {
                                            currentPage += 1
                                        }
                                    } else {
                                        await viewModel.savePreferences()
                                    }
                                }
                            }) {
                                HStack {
                                    Text(currentPage < 2 ? "Next" : "Save Preferences")
                                    Image(systemName: currentPage < 2 ? "chevron.right" : "checkmark.circle.fill")
                                }
                                .font(.headline)
                                .foregroundColor(AppColors.BackgroundDark)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            AppColors.GreenAccent,
                                            AppColors.GreenLight
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: AppColors.GreenAccent.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                        .padding(.top, 16)
                    }
                    
                    // Navigation automatique vers TabBarView après save
                    NavigationLink(destination: TabBarView(), isActive: $viewModel.navigateToHome) {
                        EmptyView()
                    }
                    .opacity(0)
                }
            }
            .navigationTitle("Adventure Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.BackgroundDark.opacity(0.95), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task {
                await viewModel.loadPreferences()
            }
        }
    }
    
    private var pageTitle: String {
        switch currentPage {
        case 0: return "🚴 Cycling Preferences"
        case 1: return "🥾 Hiking Preferences"
        case 2: return "🏕️ Camping Preferences"
        default: return ""
        }
    }
}

// MARK: - Preview
struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
            .preferredColorScheme(.dark)
    }
}
