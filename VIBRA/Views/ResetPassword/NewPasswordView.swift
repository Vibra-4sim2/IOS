//
//  NewPasswordView.swift
//  VIBRA
//
//  Created by mac book pro on 11/9/25.
//
//
//  NewPasswordView.swift
//  VIBRA
//

import SwiftUI

struct NewPasswordView: View {
    @ObservedObject var viewModel: ResetPasswordViewModel
    @State private var showPassword = false
    
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
                    Text("Set a new password")
                        .foregroundColor(.white)
                        .font(.title.bold())
                    Text("Your password must be strong and secure")
                        .foregroundColor(.green.opacity(0.8))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(.green)
                        if showPassword {
                            TextField("New Password", text: $viewModel.newPassword)
                                .foregroundColor(.white)
                        } else {
                            SecureField("New Password", text: $viewModel.newPassword)
                                .foregroundColor(.white)
                        }
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1)))
                }
                
                Button(action: {
                    Task { await viewModel.resetPasswordAction() }
                }) {
                    Text("Reset Password")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.newPassword.isEmpty ? Color.gray : Color.green)
                        .cornerRadius(10)
                }
                .disabled(viewModel.newPassword.isEmpty)
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.top, 4)
                }
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .frame(maxWidth: 400)
        }
    }
}
#Preview {
    NewPasswordView(viewModel: ResetPasswordViewModel())
}
