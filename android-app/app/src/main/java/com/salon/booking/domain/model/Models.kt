package com.salon.booking.domain.model

import com.google.gson.annotations.SerializedName

data class User(
    @SerializedName("_id", alternate = ["id"]) val id: String = "",
    val name: String = "",
    val email: String? = null,
    val phone: String? = null,
    val profileImageUrl: String? = null,
    val role: String = "",
    val createdAt: String? = null
)

data class SalonService(
    @SerializedName("_id", alternate = ["id"]) val id: String = "",
    val name: String = "",
    val description: String? = null,
    val durationMinutes: Int = 0,
    val price: Double = 0.0,
    val category: String? = null,
    val imageUrl: String? = null
)

data class ArtistServiceEntry(
    val service: SalonService? = null,
    val customPrice: Double? = null,
    val customDuration: Int? = null
)

data class Artist(
    @SerializedName("_id", alternate = ["id"]) val id: String = "",
    val name: String = "",
    val phone: String? = null,
    val email: String? = null,
    val profileImageUrl: String? = null,
    val bio: String? = null,
    val experienceYears: Int = 0,
    val avgRating: Double = 0.0,
    val totalReviews: Int = 0,
    val isActive: Boolean = true,
    val services: List<ArtistServiceEntry>? = null
)

data class TimeSlot(
    val startTime: String = "",
    val endTime: String = "",
    val available: Boolean = true
)

data class SlotResponse(
    val date: String = "",
    val artistId: String = "",
    val serviceId: String = "",
    val serviceDuration: Int = 0,
    val slots: List<TimeSlot> = emptyList()
)

data class Appointment(
    @SerializedName("_id", alternate = ["id"]) val id: String = "",
    val bookingRef: String = "",
    val artist: AppointmentArtist = AppointmentArtist(),
    val service: AppointmentService = AppointmentService(),
    val appointmentDate: String = "",
    val startTime: String = "",
    val endTime: String = "",
    val status: String = "",
    val originalPrice: Double = 0.0,
    val finalPrice: Double = 0.0,
    val notes: String? = null,
    val couponCode: String? = null,
    val paymentMethod: String? = null,
    val paymentStatus: String? = null,
    val createdAt: String? = null
)

// Flattened in appointment response (backend sends `id` not `_id`)
data class AppointmentArtist(
    val id: String = "",
    val name: String = "",
    val phone: String? = null,
    val email: String? = null,
    val profileImageUrl: String? = null,
    val bio: String? = null,
    val experienceYears: Int? = null,
    val avgRating: Double? = null,
    val totalReviews: Int? = null,
    val isActive: Boolean? = null
)

data class AppointmentService(
    val id: String = "",
    val name: String = "",
    val description: String? = null,
    val durationMinutes: Int? = null,
    val price: Double? = null,
    val category: String? = null,
    val imageUrl: String? = null
)

data class Review(
    @SerializedName("_id", alternate = ["id"]) val id: String = "",
    val userName: String = "",
    val userProfileImage: String? = null,
    val rating: Int = 0,
    val comment: String? = null,
    val adminReply: String? = null,
    val serviceName: String = "",
    val createdAt: String? = null
)

data class AppNotification(
    @SerializedName("_id", alternate = ["id"]) val id: String = "",
    val title: String = "",
    val body: String = "",
    val type: String = "",
    val referenceId: String? = null,
    val isRead: Boolean = false,
    val sentAt: String? = null
)

data class AuthResponse(
    val accessToken: String = "",
    val refreshToken: String = "",
    val user: User = User()
)

data class CouponValidationResponse(
    val valid: Boolean = false,
    val discountAmount: Double? = null,
    val message: String = ""
)

data class PaginatedResponse<T>(
    val content: List<T> = emptyList(),
    val totalElements: Int = 0,
    val totalPages: Int = 0,
    val number: Int = 0,
    val size: Int = 0
)

// Admin Models
data class AdminDashboard(
    val todayBookings: Int = 0,
    val todayRevenue: Double = 0.0,
    val activeArtists: Int = 0,
    val totalCustomers: Int = 0,
    val recentBookings: List<AdminBooking> = emptyList(),
    val peakHours: List<PeakHour> = emptyList()
)

data class AdminBooking(
    @SerializedName("_id", alternate = ["id"]) val id: String = "",
    val artist: AdminRef? = null,
    val service: AdminRef? = null,
    val user: AdminUserRef? = null,
    val startTime: String = "",
    val endTime: String = "",
    val status: String = "",
    val appointmentDate: String? = null,
    val bookingRef: String? = null,
    val originalPrice: Double? = null,
    val finalPrice: Double? = null
)

data class AdminRef(
    @SerializedName("_id", alternate = ["id"]) val id: String? = null,
    val name: String? = null
)

data class AdminUserRef(
    @SerializedName("_id", alternate = ["id"]) val id: String? = null,
    val name: String? = null,
    val email: String? = null,
    val phone: String? = null
)

data class PeakHour(
    val hour: Int = 0,
    val bookingCount: Int = 0
)

data class RevenueReport(
    val totalRevenue: Double = 0.0,
    val period: String = "",
    val breakdown: List<RevenueBreakdown> = emptyList()
)

data class RevenueBreakdown(
    val date: String = "",
    val revenue: Double = 0.0,
    val bookingCount: Int = 0
)

data class StatusUpdateRequest(val status: String)
