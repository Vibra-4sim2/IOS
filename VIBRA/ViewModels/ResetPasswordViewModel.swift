//
//  ResetPasswordViewModel.swift
//  VIBRA
//
//  Created by mac book pro on 11/9/25.
//

import Foundation
import Combine

@MainActor
final class ResetPasswordViewModel: ObservableObject {
    
    
    // MARK: - Étapes du reset
    enum Step {
        case enterEmail
        case verifyCode
        case newPassword
        case done
    }
    
    // MARK: - Published Properties
    @Published var step: Step = .enterEmail
    @Published var email: String = ""
    @Published var code: String = ""
    @Published var newPassword: String = ""
    @Published var message: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Forgot Password
    func sendResetCode() async {
        guard !email.isEmpty else {
            errorMessage = "Veuillez entrer votre email."
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await AuthService.shared.forgotPassword(email: email)
            message = response.message
            step = .verifyCode
        } catch {
            errorMessage = "Erreur : \(error.localizedDescription)"
        }
    }
    
    // MARK: - Verify Code
    func verifyCodeAction() async {
        guard !code.isEmpty else {
            errorMessage = "Veuillez entrer le code reçu par email."
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await AuthService.shared.verifyResetCode(email: email, code: code)
            message = response.message
            step = .newPassword
        } catch {
            errorMessage = "Erreur : \(error.localizedDescription)"
        }
    }
    
    // MARK: - Reset Password
    func resetPasswordAction() async {
        guard !newPassword.isEmpty else {
            errorMessage = "Veuillez entrer un nouveau mot de passe."
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await AuthService.shared.resetPassword(email: email, code: code, newPassword: newPassword)
            message = response.message
            step = .done
        } catch {
            errorMessage = "Erreur : \(error.localizedDescription)"
        }
    }
    
    // MARK: - Reset ViewModel (utile si tu veux réessayer)
    func reset() {
        email = ""
        code = ""
        newPassword = ""
        message = ""
        errorMessage = nil
        step = .enterEmail
    }
}

