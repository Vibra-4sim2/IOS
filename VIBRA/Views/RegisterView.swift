import SwiftUI

struct RegisterView: View {
    // MARK: - ViewModel
    @StateObject private var viewModel = RegisterViewModel()

    // MARK: - Body
    var body: some View {
        ZStack {
            // MARK: Background
            Image("login_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(0.55)
                .ignoresSafeArea()

            // MARK: Main Content
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)

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

                        Text("Create your account to start exploring")
                            .foregroundColor(.green.opacity(0.8))
                            .font(.subheadline)
                    }
                    .multilineTextAlignment(.center)

                    // MARK: Input Fields
                    VStack(spacing: 16) {
                        inputField(icon: "person", placeholder: "First name", text: $viewModel.firstName)
                        inputField(icon: "person", placeholder: "Last name", text: $viewModel.lastName)

                        // ⚧ Gender Picker
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Gender")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.footnote)

                            Picker("Select Gender", selection: $viewModel.gender) {
                                Text("Male").tag("Male")
                                Text("Female").tag("Female")
                                Text("Other").tag("Other")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(10)
                        }

                        inputField(icon: "envelope", placeholder: "Enter your email", text: $viewModel.email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)

                        secureField(icon: "lock", placeholder: "Enter your password", text: $viewModel.password)
                        secureField(icon: "lock.rotation", placeholder: "Confirm password", text: $viewModel.confirmPassword)

                        // ✅ Terms Toggle
                        HStack {
                            Toggle(isOn: $viewModel.agreeTerms) {
                                Text("I agree to the Terms & Privacy Policy")
                                    .foregroundColor(.white)
                                    .font(.footnote)
                            }
                            .toggleStyle(RegisterCheckboxToggleStyle())
                        }
                    }

                    // MARK: Sign Up Button
                    Button(action: {
                        viewModel.register()
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign up")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((viewModel.agreeTerms && !viewModel.gender.isEmpty) ? Color.green : Color.gray)
                        .cornerRadius(10)
                    }
                    .disabled(!viewModel.agreeTerms || viewModel.isLoading || viewModel.gender.isEmpty)

                    // MARK: Already Have Account
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(.white.opacity(0.8))
                        Button(action: {
                            // Navigation vers Login
                        }) {
                            Text("Log in")
                                .foregroundColor(.green)
                        }
                    }
                    .font(.footnote)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 30)
                .frame(maxWidth: 400)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            }
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text(viewModel.alertTitle),
                  message: Text(viewModel.alertMessage),
                  dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Custom Input Field
    private func inputField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)
            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.green.opacity(0.7))
                }
                TextField("", text: text)
                    .foregroundColor(.white)
                    .accentColor(.green)
            }
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1)))
    }

    // MARK: - Secure Input Field
    private func secureField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)
            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.green.opacity(0.7))
                }
                SecureField("", text: text)
                    .foregroundColor(.white)
                    .accentColor(.green)
            }
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1)))
    }
}

// MARK: - Checkbox Style
struct RegisterCheckboxToggleStyle: ToggleStyle {
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
    RegisterView()
}
