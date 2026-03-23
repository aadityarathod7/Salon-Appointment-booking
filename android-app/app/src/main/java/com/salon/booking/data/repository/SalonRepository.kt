package com.salon.booking.data.repository

import com.salon.booking.data.remote.api.SalonApi
import com.salon.booking.data.remote.dto.*
import com.salon.booking.domain.model.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SalonRepository @Inject constructor(
    private val api: SalonApi
) {

    // Services
    suspend fun getServices(category: String? = null): Result<List<SalonService>> =
        apiCall { api.getServices(category) }

    suspend fun getArtistsForService(serviceId: Long): Result<List<Artist>> =
        apiCall { api.getArtistsForService(serviceId) }

    // Artists
    suspend fun getArtists(): Result<List<Artist>> =
        apiCall { api.getArtists() }

    suspend fun getArtist(id: Long): Result<Artist> =
        apiCall { api.getArtist(id) }

    suspend fun getArtistReviews(id: Long): Result<PaginatedResponse<Review>> =
        apiCall { api.getArtistReviews(id) }

    // Slots
    suspend fun getAvailableSlots(artistId: Long, serviceId: Long, date: String): Result<SlotResponse> =
        apiCall { api.getAvailableSlots(artistId, serviceId, date) }

    // Appointments
    suspend fun createBooking(request: BookingRequest): Result<Appointment> =
        apiCall { api.createBooking(request) }

    suspend fun getAppointments(status: String? = null): Result<PaginatedResponse<Appointment>> =
        apiCall { api.getAppointments(status) }

    suspend fun cancelAppointment(id: Long): Result<Appointment> =
        apiCall { api.cancelAppointment(id, CancelRequest()) }

    suspend fun rescheduleAppointment(id: Long, date: String, startTime: String): Result<Appointment> =
        apiCall { api.rescheduleAppointment(id, RescheduleRequest(date, startTime)) }

    // Reviews
    suspend fun createReview(appointmentId: Long, rating: Int, comment: String?): Result<Review> =
        apiCall { api.createReview(ReviewRequest(appointmentId, rating, comment)) }

    // Coupons
    suspend fun validateCoupon(code: String, serviceId: Long): Result<CouponValidationResponse> =
        apiCall { api.validateCoupon(ValidateCouponRequest(code, serviceId)) }

    // Notifications
    suspend fun getNotifications(): Result<PaginatedResponse<AppNotification>> =
        apiCall { api.getNotifications() }

    suspend fun markAllNotificationsRead(): Result<Unit> =
        apiCall { api.markAllNotificationsRead() }

    private suspend fun <T> apiCall(call: suspend () -> com.salon.booking.data.remote.dto.ApiResponse<T>): Result<T> {
        return try {
            val response = call()
            if (response.success && response.data != null) {
                Result.success(response.data)
            } else {
                Result.failure(Exception(response.message ?: "Request failed"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
