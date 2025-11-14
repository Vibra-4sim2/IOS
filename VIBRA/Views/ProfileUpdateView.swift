//
//  ProfileUpdateView.swift
//  VIBRA
//
//  Created by mac book pro on 11/10/25.
//

import SwiftUI

struct ProfileUpdateView: View {
    @StateObject var viewModel: ProfileUpdateViewModel

    init(viewModel: ProfileUpdateViewModel = ProfileUpdateViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {

                    // Header
                    VStack(spacing: 12) {
                        Image("profile")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 2))

                        Text("\(viewModel.firstName) \(viewModel.lastName)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Text(viewModel.email)
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    .padding(.top, 40)

                    // Formulaire
                    VStack(spacing: 16) {
                        CustomTextField(title: "First Name", text: $viewModel.firstName)
                        CustomTextField(title: "Last Name", text: $viewModel.lastName)
                        CustomTextField(title: "Gender", text: $viewModel.gender)
                        CustomTextField(title: "Email", text: $viewModel.email, keyboard: .emailAddress)

                        SecureField("Password (laisser vide pour ne pas changer)", text: $viewModel.password)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)

                    // Bouton Update
                    Button(action: {
                        Task { await viewModel.updateUser() }
                    }) {
                        Text("Update Profile")
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(12)
                            .shadow(color: .green.opacity(0.5), radius: 5, x: 0, y: 3)
                    }
                    .padding(.horizontal)
                    .disabled(viewModel.isLoading)

                    // Messages
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    if let success = viewModel.successMessage {
                        Text(success)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Spacer()
                }
            }

            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .green))
            }
        }
        .task { await viewModel.loadUser() }
    }
}
struct CustomTextField: View {
    var title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(keyboard)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.white)
    }
}
#Preview {
    ProfileUpdateView(viewModel: {
        let vm = ProfileUpdateViewModel()
        vm.firstName = "Karim"
        vm.lastName = "Ouertatani"
        vm.gender = "Male"
        vm.email = "karim@example.com"
        vm.password = "" // Vide = ne change pas le mot de passe
        return vm
    }())
}

