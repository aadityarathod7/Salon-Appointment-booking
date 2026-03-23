import SwiftUI

struct OTPVerificationView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var phone = ""
    @State private var otp = ""
    @State private var otpSent = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "phone.badge.checkmark")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)

                if !otpSent {
                    VStack(spacing: 16) {
                        Text("Enter your phone number")
                            .font(.headline)

                        TextField("Phone Number", text: $phone)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.phonePad)
                            .padding(.horizontal, 32)

                        Button("Send OTP") {
                            Task {
                                await authManager.sendOtp(phone: phone)
                                otpSent = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .disabled(phone.isEmpty || authManager.isLoading)
                    }
                } else {
                    VStack(spacing: 16) {
                        Text("Enter the OTP sent to \(phone)")
                            .font(.headline)

                        TextField("OTP", text: $otp)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .padding(.horizontal, 32)

                        Button("Verify") {
                            Task {
                                await authManager.verifyOtp(phone: phone, otp: otp)
                                if authManager.isAuthenticated { dismiss() }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .disabled(otp.isEmpty || authManager.isLoading)

                        Button("Resend OTP") {
                            Task { await authManager.sendOtp(phone: phone) }
                        }
                        .foregroundColor(.purple)
                    }
                }

                if let error = authManager.errorMessage {
                    Text(error).foregroundColor(.red).font(.caption)
                }

                Spacer()
            }
            .navigationTitle("OTP Login")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
