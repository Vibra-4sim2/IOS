//
//  ForgotPasswordView.swift
//  VIBRA
//
//  Created by mac book pro on 11/6/25.
//

//
//  ForgotPasswordView.swift
//  VIBRA
//

import SwiftUI

struct ForgotPasswordView: View {
    @ObservedObject var viewModel: ResetPasswordViewModel
    
    var body: some View {
        ZStack {
            Image("login_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            Color.black.opacity(0.55).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer(minLength: 40)
                
                VStack(spacing: 10) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .shadow(radius: 8)
                        .padding(.bottom, 4)
                    
                    Text("Forgot your password?")
                        .foregroundColor(.white)
                        .font(.title.bold())
                    Text("Enter your email to reset it")
                        .foregroundColor(.green.opacity(0.8))
                        .font(.subheadline)
                }
                
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.green)
                        TextField("Email", text: $viewModel.email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .foregroundColor(.white)
                            .accentColor(.green)
                    }
                    .padding()
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1)))
                }
                
                Button(action: {
                    Task { await viewModel.sendResetCode() }
                }) {
                    HStack {
                        Text("Send reset code")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.email.isEmpty ? Color.gray : Color.green)
                    .cornerRadius(10)
                }
                .disabled(viewModel.email.isEmpty)
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.top, 4)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 30)
            .frame(maxWidth: 400)
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
    
    // MARK: - Helpers
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#Preview {
    ForgotPasswordView(viewModel: ResetPasswordViewModel())
}
