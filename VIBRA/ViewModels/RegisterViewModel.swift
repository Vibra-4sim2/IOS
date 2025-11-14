//
//  RegisterViewModel.swift
//  VIBRA
//
//  Created by mac book pro on 11/7/25.
//
import Foundation
import Combine

@MainActor
final class RegisterViewModel: ObservableObject {
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var gender = "" // ✅ Ajouté pour correspondre au DTO
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var avatar: String? = nil // ✅ optionnel
    @Published var role: String? = nil   // ✅ optionnel
    @Published var agreeTerms = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isRegistered = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    func register() {
        Task { await registerAsync() }
    }
    
    func registerAsync() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await AuthService.shared.register(
                firstName: firstName,
                lastName: lastName,
                gender: gender,        // ✅ obligatoire
                email: email,
                password: password,
                avatar: avatar,        // ✅ optionnel
                role: role             // ✅ optionnel
            )
            
            print("✅ User created: \(user.email)")
            isRegistered = true
            alertTitle = "Success"
            alertMessage = "Your account has been created."
            showAlert = true
            
        } catch {
            errorMessage = "Erreur lors de l’inscription."
            alertTitle = "Registration Failed"
            alertMessage = errorMessage ?? "An unknown error occurred."
            showAlert = true
            print("❌ Register error: \(error)")
        }
        
        isLoading = false
    }
}
