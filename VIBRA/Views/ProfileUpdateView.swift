//
//  ProfileUpdateView.swift
//  VIBRA
//
//  Created by mac book pro on 11/10/25.
//

import SwiftUI

@MainActor
struct ProfileUpdateView: View {
    @StateObject var viewModel: ProfileUpdateViewModel

    // Image picker sheet
    @State private var showingImagePicker = false
    @State private var pickedImage: UIImage? = nil

    init(viewModel: ProfileUpdateViewModel = ProfileUpdateViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {

                    // Header with avatar + pick button
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            Group {
                                if let picked = pickedImage {
                                    Image(uiImage: picked)
                                        .resizable()
                                } else if let avatar = viewModel.avatarURL, let url = URL(string: avatar) {
                                    AsyncImage(url: url) { image in
                                        image.resizable()
                                    } placeholder: {
                                        Image("profile").resizable()
                                    }
                                } else {
                                    Image("profile").resizable()
                                }
                            }
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 2))

                            Button(action: { showingImagePicker = true }) {
                                Image(systemName: "camera.fill")
                                    .padding(8)
                                    .background(Color.green)
                                    .foregroundColor(.black)
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                            }
                            .offset(x: -6, y: -6)
                        }

                        Text("\(viewModel.firstName) \(viewModel.lastName)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Text(viewModel.email)
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    .padding(.top, 40)

                    // Formulaire sans gender, ajout birthday
                    VStack(spacing: 16) {
                        CustomTextField(title: "First Name", text: $viewModel.firstName)
                        CustomTextField(title: "Last Name", text: $viewModel.lastName)
                        CustomTextField(title: "Email", text: $viewModel.email, keyboard: .emailAddress)

                        // Birthday picker (required)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Birthday")
                                .foregroundColor(.gray)
                                .font(.footnote)
                            DatePicker("Birthday", selection: Binding(get: {
                                viewModel.birthday ?? Date()
                            }, set: { newDate in
                                viewModel.birthday = newDate
                            }), displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .labelsHidden()
                        }

                        SecureField("Password (laisser vide pour ne pas changer)", text: $viewModel.password)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)

                    // Buttons: Upload Avatar (if picked) and Update Profile
                    VStack(spacing: 12) {
                        if pickedImage != nil {
                            Button(action: {
                                guard let img = pickedImage else { return }
                                Task { await viewModel.uploadAvatar(uiImage: img) }
                            }) {
                                Text("Upload Avatar")
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                            .disabled(viewModel.isLoading)
                            .padding(.horizontal)
                        }

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
                    }

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
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $pickedImage)
        }
        .onChange(of: pickedImage) { newImage in
            // Optionally immediately show preview (we already set pickedImage)
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

// Simple UIImagePickerController wrapper
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            var selected: UIImage?
            if let edited = info[.editedImage] as? UIImage { selected = edited }
            else if let original = info[.originalImage] as? UIImage { selected = original }
            parent.image = selected
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    ProfileUpdateView(viewModel: {
        let vm = ProfileUpdateViewModel()
        vm.firstName = "Karim"
        vm.lastName = "Ouertatani"
        vm.email = "karim@example.com"
        // set a demo birthday
        vm.birthday = Date(timeIntervalSince1970: 0)
        return vm
    }())
}

