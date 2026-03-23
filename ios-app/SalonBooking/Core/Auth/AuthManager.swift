import Foundation
import SwiftUI

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        isAuthenticated = TokenManager.shared.accessToken != nil
        if isAuthenticated {
            Task { await loadProfile() }
        }
    }

    func login(emailOrPhone: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let request = LoginRequest(emailOrPhone: emailOrPhone, password: password)
            let response: ApiResponse<AuthResponse> = try await APIClient.shared.post(
                "/auth/login", body: request, authenticated: false
            )
            if let auth = response.data {
                TokenManager.shared.saveTokens(
                    accessToken: auth.accessToken,
                    refreshToken: auth.refreshToken
                )
                currentUser = auth.user
                isAuthenticated = true
            } else {
                errorMessage = response.message ?? "Login failed"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func register(name: String, email: String?, phone: String?, password: String?) async {
        isLoading = true
        errorMessage = nil

        do {
            let request = RegisterRequest(name: name, email: email, phone: phone, password: password)
            let response: ApiResponse<AuthResponse> = try await APIClient.shared.post(
                "/auth/register", body: request, authenticated: false
            )
            if let auth = response.data {
                TokenManager.shared.saveTokens(
                    accessToken: auth.accessToken,
                    refreshToken: auth.refreshToken
                )
                currentUser = auth.user
                isAuthenticated = true
            } else {
                errorMessage = response.message ?? "Registration failed"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func sendOtp(phone: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let request = OtpSendRequest(phone: phone)
            let _: ApiResponse<String> = try await APIClient.shared.post(
                "/auth/otp/send", body: request, authenticated: false
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func verifyOtp(phone: String, otp: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let request = OtpVerifyRequest(phone: phone, otp: otp)
            let response: ApiResponse<AuthResponse> = try await APIClient.shared.post(
                "/auth/otp/verify", body: request, authenticated: false
            )
            if let auth = response.data {
                TokenManager.shared.saveTokens(
                    accessToken: auth.accessToken,
                    refreshToken: auth.refreshToken
                )
                currentUser = auth.user
                isAuthenticated = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func logout() {
        TokenManager.shared.clearTokens()
        currentUser = nil
        isAuthenticated = false
    }

    func loadProfile() async {
        do {
            let response: ApiResponse<User> = try await APIClient.shared.get("/users/me")
            currentUser = response.data
        } catch {
            // Token might be expired
            logout()
        }
    }
}
