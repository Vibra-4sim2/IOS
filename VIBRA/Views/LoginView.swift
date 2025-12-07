//
//  LoginView.swift
//  VIBRA
//

import SwiftUI

struct LoginView: View {
    // MARK: - ViewModel
    @StateObject private var viewModel = LoginViewModel()
    @State private var rememberMe = false
    
    // MARK: - Alert state
    @State private var showAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Animated Background Gradient
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                // MARK: - Content
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 80)
                        
                        VStack(spacing: 32) {
                            
                            // MARK: Header
                            VStack(spacing: 16) {
                                Image("vibra_logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: AppColors.GlowGreen.opacity(0.6), radius: 20, x: 0, y: 8)
                                    .padding(.bottom, 8)
                                
                                Text("Welcome Back")
                                    .foregroundColor(AppColors.TextPrimary)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                
                                Text("Log in to continue your cycling journey")
                                    .foregroundColor(AppColors.TextSecondary)
                                    .font(.system(size: 16, weight: .medium))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.bottom, 8)
                            
                            // MARK: Login Card
                            VStack(spacing: 20) {
                                
                                // MARK: Email & Password Fields
                                VStack(spacing: 16) {
                                    customInputField(
                                        icon: "envelope.fill",
                                        placeholder: "Email address",
                                        text: $viewModel.email,
                                        isSecure: false
                                    )
                                    
                                    customInputField(
                                        icon: "lock.fill",
                                        placeholder: "Password",
                                        text: $viewModel.password,
                                        isSecure: true
                                    )
                                }
                                
                                // MARK: Remember Me / Forgot Password
                                HStack {
                                    Toggle(isOn: $rememberMe) {
                                        Text("Remember me")
                                            .foregroundColor(AppColors.TextSecondary)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .toggleStyle(CheckboxToggleStyle())
                                    
                                    Spacer()
                                    
                                    NavigationLink(destination: ResetPasswordFlowView()) {
                                        Text("Forgot password?")
                                            .foregroundColor(AppColors.GreenAccent)
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                }
                                
                                // MARK: Login Button
                                Button {
                                    Task {
                                        await viewModel.login(stayConnected: rememberMe)
                                    }
                                } label: {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(AppColors.GreenAccent)
                                            .cornerRadius(14)
                                    } else {
                                        HStack(spacing: 8) {
                                            Text("Log in")
                                                .font(.system(size: 17, weight: .bold))
                                            Image(systemName: "arrow.right")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(AppColors.GreenAccent)
                                        .cornerRadius(14)
                                        .shadow(color: AppColors.GlowGreen.opacity(0.5), radius: 12, x: 0, y: 6)
                                    }
                                }
                                .disabled(viewModel.isLoading)
                                
                            }
                            .padding(24)
                            .background(AppColors.CardDark)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(AppColors.BorderColor, lineWidth: 1)
                            )
                            .shadow(color: AppColors.ShadowColor.opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            // MARK: Register Link
                            HStack(spacing: 6) {
                                Text("Don't have an account?")
                                    .foregroundColor(AppColors.TextSecondary)
                                NavigationLink(destination: RegisterView()) {
                                    Text("Create account")
                                        .foregroundColor(AppColors.GreenAccent)
                                        .fontWeight(.semibold)
                                }
                            }
                            .font(.system(size: 15))
                            
                            // MARK: Divider
                            HStack(spacing: 16) {
                                Rectangle()
                                    .fill(AppColors.DividerColor)
                                    .frame(height: 1)
                                
                                Text("or continue with")
                                    .foregroundColor(AppColors.TextTertiary)
                                    .font(.system(size: 13, weight: .medium))
                                
                                Rectangle()
                                    .fill(AppColors.DividerColor)
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 8)
                            
                            // MARK: Social Login Buttons
                            HStack(spacing: 16) {
                                ForEach([
                                    ("applelogo", "Apple"),
                                    ("globe", "Google"),
                                    ("f.circle.fill", "Facebook")
                                ], id: \.0) { icon, name in
                                    Button(action: {}) {
                                        VStack(spacing: 8) {
                                            Image(systemName: icon)
                                                .foregroundColor(AppColors.GreenAccent)
                                                .font(.system(size: 24, weight: .medium))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(AppColors.CardGlass)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(AppColors.BorderColor, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .frame(maxWidth: 440)
                        
                        Spacer(minLength: 60)
                    }
                }
                
                // MARK: Navigation automatique si connecté
                NavigationLink(destination: TabBarView(), isActive: $viewModel.isLoggedIn) {
                    EmptyView()
                }
                .opacity(0)
            }
        }
        .onAppear {
            viewModel.checkIfAlreadyLoggedIn()
        }
        .onChange(of: viewModel.errorMessage) { _, newValue in
            if newValue != nil {
                showAlert = true
            }
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Custom Field
    @ViewBuilder
    private func customInputField(icon: String, placeholder: String, text: Binding<String>, isSecure: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppColors.GreenAccent)
                .font(.system(size: 18))
                .frame(width: 24)
            
            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundColor(AppColors.TextTertiary)
                        .font(.system(size: 16))
                }
                
                if isSecure {
                    SecureField("", text: text)
                        .foregroundColor(AppColors.TextPrimary)
                        .font(.system(size: 16))
                        .accentColor(AppColors.GreenAccent)
                } else {
                    TextField("", text: text)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .foregroundColor(AppColors.TextPrimary)
                        .font(.system(size: 16))
                        .accentColor(AppColors.GreenAccent)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppColors.CardGlass)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.BorderColor, lineWidth: 1)
        )
    }
}

// MARK: - Animated Gradient Background
struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                AppColors.BackgroundGradientStart,
                AppColors.BackgroundGradientEnd,
                AppColors.GreenDark.opacity(0.3),
                AppColors.BackgroundGradientStart
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .onAppear {
            withAnimation(
                .easeInOut(duration: 5)
                .repeatForever(autoreverses: true)
            ) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Checkbox Style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? AppColors.GreenAccent : AppColors.TextTertiary)
                .font(.system(size: 20))
                .onTapGesture { configuration.isOn.toggle() }
            configuration.label
        }
    }
}

// MARK: - Preview
#Preview {
    LoginView()
}
