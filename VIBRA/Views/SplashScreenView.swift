//
//  SplashScreenView.swift
//  VIBRA
//
//  Created by mac book pro on 11/9/25.
//
import SwiftUI

struct SplashScreenView: View {
    @State private var animate = false
    @State private var fadeOut = false
    @State private var goToHome = false
    @State private var goToLogin = false
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // 🌌 Dégradé sombre premium
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0, green: 0.15, blue: 0),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // ✨ Cercles de glow animés (effet néon élégant)
                Circle()
                    .fill(Color.green.opacity(0.25))
                    .blur(radius: 80)
                    .frame(width: 300, height: 300)
                    .offset(y: -200)
                    .opacity(animate ? 0.9 : 0.4)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animate)

                Circle()
                    .fill(Color.green.opacity(0.2))
                    .blur(radius: 100)
                    .frame(width: 250, height: 250)
                    .offset(y: 200)
                    .opacity(animate ? 0.6 : 0.2)
                    .animation(.easeInOut(duration: 4).repeatForever(), value: animate)

                // 🌟 Particules plus professionnelles
                ForEach(0..<20, id: \.self) { index in
                    Circle()
                        .fill(Color.green.opacity(0.35))
                        .frame(width: 3, height: 3)
                        .offset(x: CGFloat.random(in: -180...180),
                                y: CGFloat.random(in: -350...350))
                        .opacity(animate ? 0.8 : 0.3)
                        .animation(Animation.easeInOut(duration: Double.random(in: 1.5...2.5))
                            .repeatForever(), value: animate)
                }

                // 🔥 Nouveau logo + animation clean
                VStack(spacing: 8) {
                    Text("V!BRA")
                        .font(.system(size: 68, weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(color: .green.opacity(0.7), radius: 15)
                        .scaleEffect(animate ? 1.08 : 0.92)
                        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: animate)
                        .blur(radius: fadeOut ? 25 : 0)
                        .opacity(fadeOut ? 0 : 1)

                    Text("FEEL THE ENERGY")
                        .foregroundColor(.green.opacity(0.9))
                        .font(.title3.weight(.semibold))
                        .tracking(2)
                        .opacity(animate ? 1 : 0.4)
                        .animation(.easeInOut(duration: 2).repeatForever(), value: animate)
                        .blur(radius: fadeOut ? 20 : 0)
                        .opacity(fadeOut ? 0 : 1)
                }
            }
            .onAppear {
                animate = true

                Task {
                    // Vérifie la session
                    await viewModel.checkIfAlreadyLoggedIn()

                    // Animation fade-out + navigation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                        withAnimation(.easeOut(duration: 0.8)) {
                            fadeOut = true
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            if viewModel.isLoggedIn {
                                goToHome = true
                            } else {
                                goToLogin = true
                            }
                        }
                    }
                }
            }

            // Navigation auto
            .navigationDestination(isPresented: $goToHome) {
                TabBarView()
            }
            .navigationDestination(isPresented: $goToLogin) {
                LoginView()
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
