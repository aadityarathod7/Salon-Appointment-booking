import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var emailOrPhone = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var showOtpLogin = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.brandDark, Color.brand, Color.brandLight.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Logo Section
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.15))
                                .frame(width: 100, height: 100)
                            Image(systemName: "scissors")
                                .font(.system(size: 44, weight: .light))
                                .foregroundColor(.white)
                        }

                        Text("Glamour Studio")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundColor(.white)

                        Text("Book your perfect look")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer().frame(height: 50)

                    // Login Card
                    VStack(spacing: 20) {
                        VStack(spacing: 14) {
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(.textSecondary)
                                    .frame(width: 20)
                                TextField("Email or Phone", text: $emailOrPhone)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                            }
                            .padding()
                            .background(Color.surfaceBg)
                            .cornerRadius(12)

                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(.textSecondary)
                                    .frame(width: 20)
                                SecureField("Password", text: $password)
                            }
                            .padding()
                            .background(Color.surfaceBg)
                            .cornerRadius(12)
                        }

                        if let error = authManager.errorMessage {
                            Text(error)
                                .foregroundColor(.danger)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            Task { await authManager.login(emailOrPhone: emailOrPhone, password: password) }
                        } label: {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign In")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(colors: [.brand, .brandDark], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(color: .brand.opacity(0.4), radius: 8, y: 4)
                        }
                        .disabled(emailOrPhone.isEmpty || password.isEmpty || authManager.isLoading)
                        .opacity(emailOrPhone.isEmpty || password.isEmpty ? 0.6 : 1)

                        // Divider
                        HStack {
                            Rectangle().frame(height: 0.5).foregroundColor(.gray.opacity(0.3))
                            Text("OR").foregroundColor(.textSecondary).font(.caption2)
                            Rectangle().frame(height: 0.5).foregroundColor(.gray.opacity(0.3))
                        }

                        Button {
                            showOtpLogin = true
                        } label: {
                            HStack {
                                Image(systemName: "phone.fill")
                                Text("Login with OTP")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.surfaceBg)
                            .foregroundColor(.brand)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.brandLight, lineWidth: 1)
                            )
                        }
                    }
                    .padding(24)
                    .background(.white)
                    .cornerRadius(24)
                    .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
                    .padding(.horizontal, 20)

                    Spacer()

                    // Register
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(.white.opacity(0.8))
                        Button("Register") {
                            showRegister = true
                        }
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    }
                    .font(.subheadline)
                    .padding(.bottom, 30)
                }
            }
            .sheet(isPresented: $showRegister) {
                RegisterView()
            }
            .sheet(isPresented: $showOtpLogin) {
                OTPVerificationView()
            }
        }
    }
}
