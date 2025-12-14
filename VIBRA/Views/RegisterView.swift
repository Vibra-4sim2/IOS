import SwiftUI

struct RegisterView: View {
    // MARK: - ViewModel
    @StateObject private var viewModel = RegisterViewModel()
    
    // MARK: - Password visibility
    @State private var showPassword = false
    @State private var showConfirmPassword = false

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Animated Background Gradient
                AnimatedGradientBackground()
                    .ignoresSafeArea()

                // MARK: Main Content
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer(minLength: 60)

                        // MARK: Header
                        VStack(spacing: 16) {
                            Image("vibra_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: AppColors.GlowGreen.opacity(0.6), radius: 20, x: 0, y: 8)
                                .padding(.bottom, 8)

                            Text("Join the Ride")
                                .foregroundColor(AppColors.TextPrimary)
                                .font(.system(size: 32, weight: .bold, design: .rounded))

                            Text("Create your account to start exploring")
                                .foregroundColor(AppColors.TextSecondary)
                                .font(.system(size: 16, weight: .medium))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.bottom, 8)

                        // MARK: Registration Card
                        VStack(spacing: 20) {
                            
                            // MARK: Name Fields
                            VStack(spacing: 16) {
                                inputField(icon: "person.fill", placeholder: "First name", text: $viewModel.firstName)
                                inputField(icon: "person.fill", placeholder: "Last name", text: $viewModel.lastName)
                            }

                            // MARK: Gender + Birthday
                            HStack(spacing: 12) {
                                // Gender Column
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Gender")
                                        .foregroundColor(AppColors.TextSecondary)
                                        .font(.system(size: 13, weight: .semibold))

                                    Picker("Select Gender", selection: $viewModel.gender) {
                                        Text("Male").tag("Male")
                                        Text("Female").tag("Female")
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .tint(AppColors.GreenAccent)
                                    .padding(8)
                                    .background(AppColors.CardGlass)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.BorderColor, lineWidth: 1))
                                }
                                .frame(maxWidth: .infinity)

                                // Birthday Column
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Birthday")
                                        .foregroundColor(AppColors.TextSecondary)
                                        .font(.system(size: 13, weight: .semibold))

                                    DatePicker(
                                        "",
                                        selection: Binding(
                                            get: {
                                                if let birthdayStr = viewModel.birthday,
                                                   let date = ISO8601DateFormatter().date(from: birthdayStr) {
                                                    return date
                                                }
                                                return Date()
                                            },
                                            set: { newDate in
                                                viewModel.birthday = ISO8601DateFormatter().string(from: newDate)
                                            }
                                        ),
                                        displayedComponents: .date
                                    )
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .labelsHidden()
                                    .tint(AppColors.GreenAccent)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(AppColors.CardGlass)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.BorderColor, lineWidth: 1))
                                }
                                .frame(maxWidth: .infinity)
                            }

                            // MARK: Email Field
                            inputField(
                                icon: "envelope.fill",
                                placeholder: "Email address",
                                text: $viewModel.email
                            )
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)

                            // MARK: Password fields
                            passwordField(
                                icon: "lock.fill",
                                placeholder: "Password",
                                text: $viewModel.password,
                                show: $showPassword
                            )
                            
                            passwordField(
                                icon: "lock.rotation",
                                placeholder: "Confirm password",
                                text: $viewModel.confirmPassword,
                                show: $showConfirmPassword
                            )

                            // MARK: Terms Toggle
                            HStack(spacing: 8) {
                                Toggle(isOn: $viewModel.agreeTerms) {
                                    Text("I agree to the Terms & Privacy Policy")
                                        .foregroundColor(AppColors.TextSecondary)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .toggleStyle(RegisterCheckboxToggleStyle())
                            }
                            .padding(.top, 4)

                            // MARK: Sign Up Button
                            Button(action: {
                                viewModel.register()
                            }) {
                                HStack(spacing: 8) {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    } else {
                                        Text("Sign up")
                                            .font(.system(size: 17, weight: .bold))
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    (viewModel.agreeTerms && !viewModel.gender.isEmpty)
                                        ? AppColors.GreenAccent
                                        : AppColors.TextTertiary
                                )
                                .cornerRadius(14)
                                .shadow(
                                    color: (viewModel.agreeTerms && !viewModel.gender.isEmpty)
                                        ? AppColors.GlowGreen.opacity(0.5)
                                        : .clear,
                                    radius: 12, x: 0, y: 6
                                )
                            }
                            .disabled(!viewModel.agreeTerms || viewModel.isLoading || viewModel.gender.isEmpty)
                            
                        }
                        .padding(24)
                        .background(AppColors.CardDark)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(AppColors.BorderColor, lineWidth: 1)
                        )
                        .shadow(color: AppColors.ShadowColor.opacity(0.3), radius: 20, x: 0, y: 10)

                        // MARK: Already Have Account
                        HStack(spacing: 6) {
                            Text("Already have an account?")
                                .foregroundColor(AppColors.TextSecondary)
                            Button(action: {}) {
                                Text("Log in")
                                    .foregroundColor(AppColors.GreenAccent)
                                    .fontWeight(.semibold)
                            }
                        }
                        .font(.system(size: 15))

                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 24)
                    .frame(maxWidth: 440)
                    .frame(maxWidth: .infinity)
                }
            }
            // Navigation
            .navigationDestination(isPresented: $viewModel.isLoggedIn) {
                PreferencesView()
            }
            // ALERT — all error messages
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .preferredColorScheme(.dark)
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

    // MARK: - Custom Input Field
    private func inputField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppColors.GreenAccent)
                .font(.system(size: 18))
                .frame(width: 24)

            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundColor(AppColors.TextTertiary)
                        .font(.system(size: 16))
                }
                TextField("", text: text)
                    .foregroundColor(AppColors.TextPrimary)
                    .font(.system(size: 16))
                    .accentColor(AppColors.GreenAccent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppColors.CardGlass)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.BorderColor, lineWidth: 1)
        )
    }

    // MARK: - Password Field
    private func passwordField(icon: String, placeholder: String, text: Binding<String>, show: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppColors.GreenAccent)
                .font(.system(size: 18))
                .frame(width: 24)

            ZStack(alignment: .trailing) {
                HStack {
                    if show.wrappedValue {
                        TextField(placeholder, text: text)
                            .foregroundColor(AppColors.TextPrimary)
                            .font(.system(size: 16))
                            .accentColor(AppColors.GreenAccent)
                    } else {
                        SecureField(placeholder, text: text)
                            .foregroundColor(AppColors.TextPrimary)
                            .font(.system(size: 16))
                            .accentColor(AppColors.GreenAccent)
                    }
                }

                Button(action: { show.wrappedValue.toggle() }) {
                    Image(systemName: show.wrappedValue ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(AppColors.TextTertiary)
                        .font(.system(size: 16))
                }
                .padding(.trailing, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppColors.CardGlass)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.BorderColor, lineWidth: 1)
        )
    }
}


// MARK: - Checkbox Style
struct RegisterCheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? AppColors.GreenAccent : AppColors.TextTertiary)
                .font(.system(size: 20))
                .onTapGesture { configuration.isOn.toggle() }
            configuration.label
        }
    }
}

#Preview {
    RegisterView()
}
