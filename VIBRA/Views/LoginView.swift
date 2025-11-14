//
//  LoginView.swift
//  VIBRA
//

import SwiftUI

struct LoginView: View {
    // MARK: - ViewModel
    @StateObject private var viewModel = LoginViewModel()
    @State private var rememberMe = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("login_bg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                Color.black.opacity(0.55).ignoresSafeArea()
                
                VStack {
                    Spacer(minLength: 100)
                    
                    VStack(spacing: 24) {
                        // MARK: Header
                        VStack(spacing: 10) {
                            Image("logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .shadow(radius: 8)
                                .padding(.bottom, 4)
                            
                            Text("Join the ride")
                                .foregroundColor(.white)
                                .font(.title.bold())
                            
                            Text("Log in to your cycling account")
                                .foregroundColor(.green.opacity(0.8))
                                .font(.subheadline)
                        }
                        
                        // MARK: Email & Password Fields
                        VStack(spacing: 16) {
                            customInputField(
                                icon: "envelope",
                                placeholder: "Enter your email",
                                text: $viewModel.email,
                                isSecure: false
                            )
                            
                            customInputField(
                                icon: "lock",
                                placeholder: "Enter your password",
                                text: $viewModel.password,
                                isSecure: true
                            )
                            
                            // MARK: Remember Me / Forgot Password
                            HStack {
                                Toggle(isOn: $rememberMe) {
                                    Text("Remember me")
                                        .foregroundColor(.white)
                                }
                                .toggleStyle(CheckboxToggleStyle())
                                
                                Spacer()
                                
                                NavigationLink(destination: ResetPasswordFlowView()) {
                                    Text("Forgot password?")
                                        .foregroundColor(.green)
                                }
                            }
                            .font(.footnote)
                        }
                        
                        // MARK: Login Button
                        Button {
                            Task {
                                await viewModel.login(stayConnected: rememberMe)
                            }
                        } label: {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(10)
                            } else {
                                HStack {
                                    Text("Log in")
                                        .fontWeight(.semibold)
                                    Image(systemName: "arrow.right")
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                            }
                        }
                        .disabled(viewModel.isLoading)
                        
                        // MARK: Error message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .padding(.top, 4)
                                .multilineTextAlignment(.center)
                        }
                        
                        // MARK: Create Account Link
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundColor(.white.opacity(0.8))
                            NavigationLink(destination: RegisterView()) {
                                Text("Create account")
                                    .foregroundColor(.green)
                            }
                        }
                        .font(.footnote)
                        
                        // MARK: Social Login Buttons
                        HStack(spacing: 30) {
                            ForEach(["applelogo", "globe", "f.circle"], id: \.self) { icon in
                                Button(action: {}) {
                                    Image(systemName: icon)
                                        .foregroundColor(.green)
                                        .font(.system(size: 24))
                                        .frame(width: 55, height: 55)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 30)
                    .frame(maxWidth: 400)
                    
                    Spacer(minLength: 80)
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
    }
    
    // MARK: - Custom Field
    @ViewBuilder
    private func customInputField(icon: String, placeholder: String, text: Binding<String>, isSecure: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)
            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.green.opacity(0.7))
                }
                if isSecure {
                    SecureField("", text: text)
                        .foregroundColor(.white)
                        .accentColor(.green)
                } else {
                    TextField("", text: text)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .foregroundColor(.white)
                        .accentColor(.green)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(10)
    }
}

// MARK: - Checkbox Style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .green : .gray)
                .onTapGesture { configuration.isOn.toggle() }
            configuration.label
        }
    }
}

// MARK: - Preview
#Preview {
    LoginView()
}
