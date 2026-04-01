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

    suspend fun getArtistsForService(serviceId: String): Result<List<Artist>> =
        apiCall { api.getArtistsForService(serviceId) }

    // Artists
    suspend fun getArtists(): Result<List<Artist>> =
        apiCall { api.getArtists() }

    suspend fun getArtist(id: String): Result<Artist> =
        apiCall { api.getArtist(id) }

    suspend fun getArtistReviews(id: String): Result<PaginatedResponse<Review>> =
        apiCall { api.getArtistReviews(id) }

    // Slots
    suspend fun getAvailableSlots(artistId: String, serviceId: String, date: String): Result<SlotResponse> =
        apiCall { api.getAvailableSlots(artistId, serviceId, date) }

    // Appointments
    suspend fun createBooking(request: BookingRequest): Result<Appointment> =
        apiCall { api.createBooking(request) }

    suspend fun getAppointments(status: String? = null): Result<PaginatedResponse<Appointment>> =
        apiCall { api.getAppointments(status) }

    suspend fun cancelAppointment(id: String): Result<Appointment> =
        apiCall { api.cancelAppointment(id, CancelRequest()) }

    suspend fun rescheduleAppointment(id: String, date: String, startTime: String): Result<Appointment> =
        apiCall { api.rescheduleAppointment(id, RescheduleRequest(date, startTime)) }

    // Reviews
    suspend fun createReview(appointmentId: String, rating: Int, comment: String?): Result<Review> =
        apiCall { api.createReview(ReviewRequest(appointmentId, rating, comment)) }

    // Coupons
    suspend fun validateCoupon(code: String, serviceId: String): Result<CouponValidationResponse> =
        apiCall { api.validateCoupon(ValidateCouponRequest(code, serviceId)) }

    // Notifications
    suspend fun getNotifications(): Result<PaginatedResponse<AppNotification>> =
        apiCall { api.getNotifications() }

    suspend fun markAllNotificationsRead(): Result<Unit> =
        apiCall { api.markAllNotificationsRead() }

    // Addresses
    suspend fun getAddresses(): Result<List<SavedAddress>> =
        apiCall { api.getAddresses() }

    suspend fun addAddress(request: AddAddressRequest): Result<SavedAddress> =
        apiCall { api.addAddress(request) }

    suspend fun deleteAddress(id: String): Result<Unit> =
        apiCall { api.deleteAddress(id) }

    // Coupons
    suspend fun getCoupons(): Result<List<CouponItem>> =
        apiCall { api.getCoupons() }

    // Waitlist
    suspend fun getWaitlist(): Result<List<WaitlistEntry>> =
        apiCall { api.getWaitlist() }

    suspend fun joinWaitlist(request: JoinWaitlistRequest): Result<WaitlistEntry> =
        apiCall { api.joinWaitlist(request) }

    suspend fun leaveWaitlist(id: String): Result<Unit> =
        apiCall { api.leaveWaitlist(id) }

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
