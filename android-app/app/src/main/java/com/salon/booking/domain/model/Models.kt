package com.salon.booking.domain.model

data class User(
    val id: Long,
    val name: String,
    val email: String?,
    val phone: String?,
    val profileImageUrl: String?,
    val role: String,
    val createdAt: String
)

data class SalonService(
    val id: Long,
    val name: String,
    val description: String?,
    val durationMinutes: Int,
    val price: Double,
    val category: String?,
    val imageUrl: String?
)

data class Artist(
    val id: Long,
    val name: String,
    val phone: String?,
    val email: String?,
    val profileImageUrl: String?,
    val bio: String?,
    val experienceYears: Int,
    val avgRating: Double,
    val totalReviews: Int,
    val isActive: Boolean,
    val services: List<SalonService>? = null
)

data class TimeSlot(
    val startTime: String,
    val endTime: String,
    val available: Boolean
)

data class SlotResponse(
    val date: String,
    val artistId: Long,
    val serviceId: Long,
    val serviceDuration: Int,
    val slots: List<TimeSlot>
)

data class Appointment(
    val id: Long,
    val bookingRef: String,
    val artist: Artist,
    val service: SalonService,
    val appointmentDate: String,
    val startTime: String,
    val endTime: String,
    val status: String,
    val originalPrice: Double,
    val finalPrice: Double,
    val notes: String?,
    val couponCode: String?,
    val paymentMethod: String?,
    val paymentStatus: String?,
    val createdAt: String
)

data class Review(
    val id: Long,
    val userName: String,
    val userProfileImage: String?,
    val rating: Int,
    val comment: String?,
    val adminReply: String?,
    val serviceName: String,
    val createdAt: String
)

data class AppNotification(
    val id: Long,
    val title: String,
    val body: String,
    val type: String,
    val referenceId: Long?,
    val isRead: Boolean,
    val sentAt: String?
)

data class AuthResponse(
    val accessToken: String,
    val refreshToken: String,
    val user: User
)

data class CouponValidationResponse(
    val valid: Boolean,
    val discountAmount: Double?,
    val message: String
)

data class PaginatedResponse<T>(
    val content: List<T>,
    val totalElements: Int,
    val totalPages: Int,
    val number: Int,
    val size: Int
)
