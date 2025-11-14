//
//  SplashScreenView.swift
//  VIBRA
//
//  Created by mac book pro on 11/9/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var animate = false
    @State private var goToHome = false
    @State private var goToLogin = false
    @StateObject private var viewModel = LoginViewModel() // ✅ même ViewModel que Login

    var body: some View {
        NavigationStack {
            ZStack {
                // ✅ Background noir
                Color.black.ignoresSafeArea()

                // ✅ Effet de particules lumineuses animées
                ForEach(0..<25, id: \.self) { i in
                    Circle()
                        .fill(Color.green.opacity(Double.random(in: 0.1...0.4)))
                        .frame(width: CGFloat.random(in: 2...6), height: CGFloat.random(in: 2...6))
                        .position(
                            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                            y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                        )
                        .opacity(animate ? 0.2 : 1)
                        .animation(Animation.easeInOut(duration: Double.random(in: 1...2)).repeatForever(), value: animate)
                }

                VStack(spacing: 12) {
                    // ✅ Logo principal
                    Text("V!BRA")
                        .font(.system(size: 60, weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(color: .green, radius: 12)
                        .scaleEffect(animate ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animate)

                    // ✅ Slogan
                    Text("FEEL THE ENERGY")
                        .foregroundColor(.green)
                        .font(.headline)
                        .opacity(animate ? 1 : 0.6)
                        .animation(.easeInOut(duration: 2).repeatForever(), value: animate)

                    Text("RIDE • CONNECT • THRIVE")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.subheadline)
                        .padding(.top, 2)
                }
            }
            .onAppear {
                animate = true
                Task {
                    // ✅ Vérifie la session
                    await viewModel.checkIfAlreadyLoggedIn()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        if viewModel.isLoggedIn {
                            goToHome = true
                        } else {
                            goToLogin = true
                        }
                    }
                }
            }

            // ✅ Navigation automatique
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
