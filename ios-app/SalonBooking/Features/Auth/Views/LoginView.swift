import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var emailOrPhone = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var showOtpLogin = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Logo
                VStack(spacing: 8) {
                    Image(systemName: "scissors")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    Text("Salon Booking")
                        .font(.largeTitle.bold())
                    Text("Book your perfect look")
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Login Form
                VStack(spacing: 16) {
                    TextField("Email or Phone", text: $emailOrPhone)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)

                    if let error = authManager.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    Button {
                        Task { await authManager.login(emailOrPhone: emailOrPhone, password: password) }
                    } label: {
                        if authManager.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        } else {
                            Text("Login")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .disabled(emailOrPhone.isEmpty || password.isEmpty || authManager.isLoading)
                }

                // Divider
                HStack {
                    Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                    Text("OR").foregroundColor(.secondary).font(.caption)
                    Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                }

                // OTP Login
                Button("Login with OTP") {
                    showOtpLogin = true
                }
                .foregroundColor(.purple)

                Spacer()

                // Register
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.secondary)
                    Button("Register") {
                        showRegister = true
                    }
                    .foregroundColor(.purple)
                }
            }
            .padding(.horizontal, 32)
            .sheet(isPresented: $showRegister) {
                RegisterView()
            }
            .sheet(isPresented: $showOtpLogin) {
                OTPVerificationView()
            }
        }
    }
}
