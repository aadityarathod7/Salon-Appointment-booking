import Foundation

// MARK: - API Response Wrapper
struct ApiResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
    let errors: [String]?
}

// MARK: - Auth
struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: User
}

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String?
    let phone: String?
    let profileImageUrl: String?
    let role: String
    let createdAt: String?
}

// MARK: - Service
struct SalonService: Codable, Identifiable {
    let id: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, description, durationMinutes, price, category, imageUrl
    }

    let name: String
    let description: String?
    let durationMinutes: Int
    let price: Double
    let category: String?
    let imageUrl: String?
}

// MARK: - Artist
struct ArtistService: Codable {
    let service: SalonService?
    let customPrice: Double?
    let customDuration: Int?
}

struct Artist: Codable, Identifiable {
    let id: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, phone, email, profileImageUrl, bio
        case experienceYears, avgRating, totalReviews, isActive, services
    }

    let name: String
    let phone: String?
    let email: String?
    let profileImageUrl: String?
    let bio: String?
    let experienceYears: Int
    let avgRating: Double
    let totalReviews: Int
    let isActive: Bool
    let services: [ArtistService]?
}

// MARK: - Time Slot
struct TimeSlot: Codable, Identifiable {
    var id: String { "\(startTime)-\(endTime)" }
    let startTime: String
    let endTime: String
    let available: Bool
}

struct SlotResponse: Codable {
    let date: String
    let artistId: String
    let serviceId: String
    let serviceDuration: Int
    let slots: [TimeSlot]
}

// MARK: - Appointment (formatted by backend with `id` field)
struct Appointment: Codable, Identifiable {
    let id: String
    let bookingRef: String
    let artist: AppointmentArtist
    let service: AppointmentService
    let appointmentDate: String
    let startTime: String
    let endTime: String
    let status: String
    let originalPrice: Double
    let finalPrice: Double
    let notes: String?
    let couponCode: String?
    let paymentMethod: String?
    let paymentStatus: String?
    let createdAt: String?
}

// Flattened artist/service in appointment response (no _id mapping needed, backend sends `id`)
struct AppointmentArtist: Codable {
    let id: String
    let name: String
    let phone: String?
    let email: String?
    let profileImageUrl: String?
    let bio: String?
    let experienceYears: Int?
    let avgRating: Double?
    let totalReviews: Int?
    let isActive: Bool?
}

struct AppointmentService: Codable {
    let id: String
    let name: String
    let description: String?
    let durationMinutes: Int?
    let price: Double?
    let category: String?
    let imageUrl: String?
}

// MARK: - Review
struct Review: Codable, Identifiable {
    let id: String
    let userName: String
    let userProfileImage: String?
    let rating: Int
    let comment: String?
    let adminReply: String?
    let serviceName: String
    let createdAt: String?
}

// MARK: - Notification
struct AppNotification: Codable, Identifiable {
    let id: String
    let title: String
    let body: String
    let type: String
    let referenceId: String?
    let isRead: Bool
    let sentAt: String?
}

// MARK: - Paginated Response
struct PaginatedResponse<T: Codable>: Codable {
    let content: [T]
    let totalElements: Int
    let totalPages: Int
    let number: Int
    let size: Int
}

// MARK: - Request Models
struct LoginRequest: Codable {
    let emailOrPhone: String
    let password: String
}

struct RegisterRequest: Codable {
    let name: String
    let email: String?
    let phone: String?
    let password: String?
}

struct OtpSendRequest: Codable {
    let phone: String
}

struct OtpVerifyRequest: Codable {
    let phone: String
    let otp: String
}

struct BookingRequest: Codable {
    let serviceId: String
    let artistId: String
    let date: String
    let startTime: String
    let paymentMethod: String
    let couponCode: String?
    let notes: String?
}

struct RescheduleRequest: Codable {
    let date: String
    let startTime: String
}

struct ReviewRequest: Codable {
    let appointmentId: String
    let rating: Int
    let comment: String?
}

struct CouponValidationResponse: Codable {
    let valid: Bool
    let discountAmount: Double?
    let message: String
}
