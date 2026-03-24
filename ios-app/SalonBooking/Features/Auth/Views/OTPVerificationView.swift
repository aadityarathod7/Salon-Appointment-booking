import SwiftUI

struct OTPVerificationView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var phone = ""
    @State private var otp = ["", "", "", "", "", ""]
    @State private var otpSent = false
    @FocusState private var focusedField: Int?

    var otpString: String { otp.joined() }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfaceBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer().frame(height: 40)

                    if !otpSent {
                        phoneEntryView
                    } else {
                        otpEntryView
                    }

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                            .foregroundColor(.textPrimary)
                    }
                }
            }
            .onChange(of: authManager.isAuthenticated) { _, isAuth in
                if isAuth { dismiss() }
            }
        }
    }

    // MARK: - Phone Entry
    var phoneEntryView: some View {
        VStack(spacing: 28) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.brandLight.opacity(0.3))
                    .frame(width: 90, height: 90)
                Circle()
                    .fill(Color.brandLight.opacity(0.5))
                    .frame(width: 70, height: 70)
                Image(systemName: "phone.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.brand)
            }

            VStack(spacing: 8) {
                Text("Enter your mobile number")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(.textPrimary)
                Text("We'll send you a verification code")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }

            // Phone input
            VStack(spacing: 20) {
                HStack(spacing: 12) {
                    // Country code
                    HStack(spacing: 6) {
                        Text("🇮🇳")
                            .font(.title3)
                        Text("+91")
                            .font(.body.weight(.medium))
                            .foregroundColor(.textPrimary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )

                    // Phone number
                    TextField("Mobile Number", text: $phone)
                        .keyboardType(.numberPad)
                        .font(.body)
                        .padding(14)
                        .background(.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)

                Button {
                    Task {
                        await authManager.sendOtp(phone: phone)
                        withAnimation(.spring(response: 0.4)) {
                            otpSent = true
                        }
                    }
                } label: {
                    HStack {
                        if authManager.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Send OTP")
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
                    .shadow(color: .brand.opacity(0.3), radius: 8, y: 4)
                }
                .disabled(phone.count < 10 || authManager.isLoading)
                .opacity(phone.count < 10 ? 0.5 : 1)
                .padding(.horizontal, 24)
            }

            if let error = authManager.errorMessage {
                Text(error)
                    .foregroundColor(.danger)
                    .font(.caption)
            }
        }
    }

    // MARK: - OTP Entry
    var otpEntryView: some View {
        VStack(spacing: 28) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.brandLight.opacity(0.3))
                    .frame(width: 90, height: 90)
                Circle()
                    .fill(Color.brandLight.opacity(0.5))
                    .frame(width: 70, height: 70)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.brand)
            }

            VStack(spacing: 8) {
                Text("Verify your number")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(.textPrimary)
                Text("Enter the 6-digit code sent to")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                Text("+91 \(phone)")
                    .font(.subheadline.bold())
                    .foregroundColor(.brand)
            }

            // OTP Boxes
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    TextField("", text: $otp[index])
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 22, weight: .bold))
                        .frame(width: 48, height: 56)
                        .background(.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    otp[index].isEmpty ? Color.gray.opacity(0.2) : Color.brand,
                                    lineWidth: otp[index].isEmpty ? 1 : 2
                                )
                        )
                        .focused($focusedField, equals: index)
                        .onChange(of: otp[index]) { _, newValue in
                            // Limit to 1 character
                            if newValue.count > 1 {
                                otp[index] = String(newValue.suffix(1))
                            }
                            // Auto-advance
                            if !newValue.isEmpty && index < 5 {
                                focusedField = index + 1
                            }
                        }
                }
            }
            .padding(.horizontal, 24)
            .onAppear { focusedField = 0 }

            // Verify button
            VStack(spacing: 16) {
                Button {
                    Task {
                        await authManager.verifyOtp(phone: phone, otp: otpString)
                    }
                } label: {
                    HStack {
                        if authManager.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Verify & Login")
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
                    .shadow(color: .brand.opacity(0.3), radius: 8, y: 4)
                }
                .disabled(otpString.count < 6 || authManager.isLoading)
                .opacity(otpString.count < 6 ? 0.5 : 1)

                // Resend
                HStack(spacing: 4) {
                    Text("Didn't receive code?")
                        .foregroundColor(.textSecondary)
                    Button {
                        Task { await authManager.sendOtp(phone: phone) }
                    } label: {
                        Text("Resend")
                            .fontWeight(.bold)
                            .foregroundColor(.brand)
                    }
                }
                .font(.subheadline)

                // Change number
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        otpSent = false
                        otp = ["", "", "", "", "", ""]
                    }
                } label: {
                    Text("Change number")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 24)

            if let error = authManager.errorMessage {
                Text(error)
                    .foregroundColor(.danger)
                    .font(.caption)
                    .padding(.horizontal)
            }
        }
    }
}
