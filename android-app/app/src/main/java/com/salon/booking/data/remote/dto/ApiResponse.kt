package com.salon.booking.data.remote.dto

data class ApiResponse<T>(
    val success: Boolean,
    val message: String?,
    val data: T?,
    val errors: List<String>?
)

data class LoginRequest(
    val emailOrPhone: String,
    val password: String
)

data class RegisterRequest(
    val name: String,
    val email: String?,
    val phone: String?,
    val password: String?
)

data class OtpSendRequest(val phone: String)
data class OtpVerifyRequest(val phone: String, val otp: String)
data class RefreshTokenRequest(val refreshToken: String)

data class BookingRequest(
    val serviceId: Long,
    val artistId: Long,
    val date: String,
    val startTime: String,
    val paymentMethod: String,
    val couponCode: String? = null,
    val notes: String? = null
)

data class RescheduleRequest(val date: String, val startTime: String)
data class CancelRequest(val reason: String? = null)
data class ReviewRequest(val appointmentId: Long, val rating: Int, val comment: String?)
data class ValidateCouponRequest(val code: String, val serviceId: Long)
