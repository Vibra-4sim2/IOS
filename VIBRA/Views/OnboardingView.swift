//
//  OnboardingView.swift
//  VIBRA
//
//  Created by mac book pro on 11/9/25.
//
//
//  OnboardingView.swift
//  VIBRA
//
//  Created by karim on 09/11/2025.
//

import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let highlightedTitle: String
    let description: String
    let imageName: String
}

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var navigateToLogin = false
    let green = Color(red: 76/255, green: 175/255, blue: 80/255) // #4CAF50
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Enjoy Outdoor",
            highlightedTitle: "Activities",
            description: "The hardest thing to deal with is love. Desert Ulamco is painful, gives, and is.",
            imageName: "logo"
        ),
        OnboardingPage(
            title: "Track Your",
            highlightedTitle: "Progress",
            description: "Monitor your cycling stats, distance, speed and calories burned in real-time.",
            imageName: "homme"
        ),
        OnboardingPage(
            title: "Join the",
            highlightedTitle: "Community",
            description: "Connect with cyclists worldwide, share your rides and compete with friends.",
            imageName: "camping"
        )
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // MARK: - Top Bar (Back + Skip)
                HStack {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(green)
                                .font(.system(size: 22, weight: .medium))
                        }
                    } else {
                        Spacer().frame(width: 24)
                    }
                    
                    Spacer()
                    
                    Button("Skip") {
                        navigateToLogin = true
                    }
                    .foregroundColor(green)
                    .font(.system(size: 16, weight: .medium))
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                
                // MARK: - Pager Content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index], green: green)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // MARK: - Indicators
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? green : green.opacity(0.3))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.bottom, 24)
                
                // MARK: - Next Button
                Button(action: {
                    withAnimation {
                        if currentPage < pages.count - 1 {
                            currentPage += 1
                        } else {
                            navigateToLogin = true
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(green)
                            .frame(width: 60, height: 60)
                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)
                            .font(.system(size: 26, weight: .medium))
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .fullScreenCover(isPresented: $navigateToLogin) {
            LoginView() // 👉 ta page suivante
        }
    }
}

// MARK: - Page Content
struct OnboardingPageView: View {
    let page: OnboardingPage
    let green: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            // Title
            VStack(alignment: .leading, spacing: 0) {
                Text(page.title)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                Text(page.highlightedTitle)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(green)
            }
            .padding(.bottom, 16)
            
            // Description
            Text(page.description)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 32)
            
            Spacer()
            
            // Image
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [green.opacity(0.1), .clear]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 160
                        )
                    )
                    .frame(width: 320, height: 320)
                
                Image(page.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 280, height: 280)
                    .clipShape(Circle())
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    OnboardingView()
}

