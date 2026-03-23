package com.salon.booking.data.repository

import com.salon.booking.data.local.TokenStore
import com.salon.booking.data.remote.api.SalonApi
import com.salon.booking.data.remote.dto.*
import com.salon.booking.domain.model.AuthResponse
import com.salon.booking.domain.model.User
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepository @Inject constructor(
    private val api: SalonApi,
    private val tokenStore: TokenStore
) {

    fun isLoggedIn(): Boolean = tokenStore.hasToken()

    suspend fun login(emailOrPhone: String, password: String): Result<AuthResponse> {
        return try {
            val response = api.login(LoginRequest(emailOrPhone, password))
            if (response.success && response.data != null) {
                tokenStore.saveTokens(response.data.accessToken, response.data.refreshToken)
                Result.success(response.data)
            } else {
                Result.failure(Exception(response.message ?: "Login failed"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun register(name: String, email: String?, phone: String?, password: String?): Result<AuthResponse> {
        return try {
            val response = api.register(RegisterRequest(name, email, phone, password))
            if (response.success && response.data != null) {
                tokenStore.saveTokens(response.data.accessToken, response.data.refreshToken)
                Result.success(response.data)
            } else {
                Result.failure(Exception(response.message ?: "Registration failed"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun sendOtp(phone: String): Result<Unit> {
        return try {
            api.sendOtp(OtpSendRequest(phone))
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun verifyOtp(phone: String, otp: String): Result<AuthResponse> {
        return try {
            val response = api.verifyOtp(OtpVerifyRequest(phone, otp))
            if (response.success && response.data != null) {
                tokenStore.saveTokens(response.data.accessToken, response.data.refreshToken)
                Result.success(response.data)
            } else {
                Result.failure(Exception(response.message ?: "OTP verification failed"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getProfile(): Result<User> {
        return try {
            val response = api.getProfile()
            if (response.success && response.data != null) {
                Result.success(response.data)
            } else {
                Result.failure(Exception(response.message ?: "Failed to load profile"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun logout() {
        try { api.logout() } catch (_: Exception) {}
        tokenStore.clearTokens()
    }
}
