//
//  ResetPasswordFlowView.swift
//  VIBRA
//
//  Created by mac book pro on 11/9/25.
//
//
//  ResetPasswordFlowView.swift
//  VIBRA
//

import SwiftUI

struct ResetPasswordFlowView: View {
    @StateObject private var viewModel = ResetPasswordViewModel()
    
    var body: some View {
        switch viewModel.step {
        case .enterEmail:
            ForgotPasswordView(viewModel: viewModel)
        case .verifyCode:
            VerifyCodeView(viewModel: viewModel)
        case .newPassword:
            NewPasswordView(viewModel: viewModel)
        case .done:
            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                Text("Password reset successfully!")
                    .foregroundColor(.white)
                    .font(.title2.bold())
                NavigationLink("Back to Login", destination: LoginView())
                    .foregroundColor(.green)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Image("login_bg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            )
        }
    }
}
#Preview {
    ResetPasswordFlowView()
}

