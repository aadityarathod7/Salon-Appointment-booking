package com.salon.booking.data.remote.api

import com.salon.booking.data.remote.dto.*
import com.salon.booking.domain.model.*
import retrofit2.http.*

interface SalonApi {

    // Auth
    @POST("auth/register")
    suspend fun register(@Body request: RegisterRequest): ApiResponse<AuthResponse>

    @POST("auth/login")
    suspend fun login(@Body request: LoginRequest): ApiResponse<AuthResponse>

    @POST("auth/otp/send")
    suspend fun sendOtp(@Body request: OtpSendRequest): ApiResponse<Unit>

    @POST("auth/otp/verify")
    suspend fun verifyOtp(@Body request: OtpVerifyRequest): ApiResponse<AuthResponse>

    @POST("auth/refresh")
    suspend fun refreshToken(@Body request: RefreshTokenRequest): ApiResponse<AuthResponse>

    @POST("auth/logout")
    suspend fun logout(): ApiResponse<Unit>

    // User
    @GET("users/me")
    suspend fun getProfile(): ApiResponse<User>

    // Services
    @GET("services")
    suspend fun getServices(@Query("category") category: String? = null): ApiResponse<List<SalonService>>

    @GET("services/{id}")
    suspend fun getService(@Path("id") id: String): ApiResponse<SalonService>

    @GET("services/{id}/artists")
    suspend fun getArtistsForService(@Path("id") serviceId: String): ApiResponse<List<Artist>>

    // Artists
    @GET("artists")
    suspend fun getArtists(): ApiResponse<List<Artist>>

    @GET("artists/{id}")
    suspend fun getArtist(@Path("id") id: String): ApiResponse<Artist>

    @GET("artists/{id}/reviews")
    suspend fun getArtistReviews(
        @Path("id") id: String,
        @Query("page") page: Int = 0,
        @Query("size") size: Int = 20
    ): ApiResponse<PaginatedResponse<Review>>

    // Slots
    @GET("slots/available")
    suspend fun getAvailableSlots(
        @Query("artistId") artistId: String,
        @Query("serviceId") serviceId: String,
        @Query("date") date: String
    ): ApiResponse<SlotResponse>

    // Appointments
    @POST("appointments")
    suspend fun createBooking(@Body request: BookingRequest): ApiResponse<Appointment>

    @GET("appointments")
    suspend fun getAppointments(
        @Query("status") status: String? = null,
        @Query("page") page: Int = 0,
        @Query("size") size: Int = 20
    ): ApiResponse<PaginatedResponse<Appointment>>

    @GET("appointments/{id}")
    suspend fun getAppointment(@Path("id") id: String): ApiResponse<Appointment>

    @PUT("appointments/{id}/cancel")
    suspend fun cancelAppointment(@Path("id") id: String, @Body request: CancelRequest): ApiResponse<Appointment>

    @PUT("appointments/{id}/reschedule")
    suspend fun rescheduleAppointment(@Path("id") id: String, @Body request: RescheduleRequest): ApiResponse<Appointment>

    // Reviews
    @POST("reviews")
    suspend fun createReview(@Body request: ReviewRequest): ApiResponse<Review>

    // Coupons
    @POST("coupons/validate")
    suspend fun validateCoupon(@Body request: ValidateCouponRequest): ApiResponse<CouponValidationResponse>

    // Notifications
    @GET("notifications")
    suspend fun getNotifications(
        @Query("page") page: Int = 0,
        @Query("size") size: Int = 50
    ): ApiResponse<PaginatedResponse<AppNotification>>

    @PUT("notifications/{id}/read")
    suspend fun markNotificationRead(@Path("id") id: String): ApiResponse<Unit>

    @PUT("notifications/read-all")
    suspend fun markAllNotificationsRead(): ApiResponse<Unit>

    // Admin
    @GET("admin/dashboard")
    suspend fun getAdminDashboard(): ApiResponse<AdminDashboard>

    @GET("admin/appointments")
    suspend fun getAdminAppointments(
        @Query("date") date: String? = null,
        @Query("status") status: String? = null,
        @Query("page") page: Int = 0,
        @Query("size") size: Int = 20
    ): ApiResponse<PaginatedResponse<AdminBooking>>

    @PUT("admin/appointments/{id}/status")
    suspend fun updateAppointmentStatus(
        @Path("id") id: String,
        @Body request: StatusUpdateRequest
    ): ApiResponse<AdminBooking>

    @GET("admin/artists")
    suspend fun getAdminArtists(): ApiResponse<List<Artist>>

    @GET("admin/services")
    suspend fun getAdminServices(): ApiResponse<List<SalonService>>

    @DELETE("admin/artists/{id}")
    suspend fun deactivateArtist(@Path("id") id: String): ApiResponse<Unit>

    @DELETE("admin/services/{id}")
    suspend fun deactivateService(@Path("id") id: String): ApiResponse<Unit>

    @GET("admin/reports/revenue")
    suspend fun getRevenueReport(
        @Query("startDate") startDate: String? = null,
        @Query("endDate") endDate: String? = null
    ): ApiResponse<RevenueReport>
}
