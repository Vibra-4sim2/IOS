//
//  VerifyCodeView.swift
//  VIBRA
//
//  Created by mac book pro on 11/9/25.
//
//
//  VerifyCodeView.swift
//  VIBRA
//

import SwiftUI

struct VerifyCodeView: View {
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
                    Text("Enter the code")
                        .foregroundColor(.white)
                        .font(.title.bold())
                    Text("We have sent a verification code to \(viewModel.email)")
                        .foregroundColor(.green.opacity(0.8))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "key")
                            .foregroundColor(.green)
                        TextField("Code", text: $viewModel.code)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.numberPad)
                            .foregroundColor(.white)
                            .accentColor(.green)
                    }
                    .padding()
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1)))
                }
                
                Button(action: {
                    Task { await viewModel.verifyCodeAction() }
                }) {
                    Text("Verify Code")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.code.isEmpty ? Color.gray : Color.green)
                        .cornerRadius(10)
                }
                .disabled(viewModel.code.isEmpty)
                
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
    VerifyCodeView(viewModel: ResetPasswordViewModel())
}
