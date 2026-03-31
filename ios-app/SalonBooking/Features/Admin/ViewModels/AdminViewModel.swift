import Foundation
import SwiftUI

// MARK: - Admin Models
struct DashboardData: Codable {
    let todayBookings: Int
    let todayRevenue: Double
    let activeArtists: Int
    let totalCustomers: Int
    let recentBookings: [AdminBooking]
    let peakHours: [PeakHour]
}

struct AdminBooking: Codable, Identifiable {
    let id: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case artist, service, startTime, endTime, status, user
        case appointmentDate, bookingRef, originalPrice, finalPrice
    }

    let artist: AdminRef?
    let service: AdminRef?
    let startTime: String
    let endTime: String
    let status: String
    let user: AdminUserRef?
    let appointmentDate: String?
    let bookingRef: String?
    let originalPrice: Double?
    let finalPrice: Double?
}

struct AdminRef: Codable {
    let id: String?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
    }
}

struct AdminUserRef: Codable {
    let id: String?
    let name: String?
    let email: String?
    let phone: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, email, phone
    }
}

struct PeakHour: Codable {
    let hour: Int
    let bookingCount: Int
}

struct RevenueReport: Codable {
    let totalRevenue: Double
    let period: String
    let breakdown: [RevenueBreakdown]
}

struct RevenueBreakdown: Codable, Identifiable {
    var id: String { date }
    let date: String
    let revenue: Double
    let bookingCount: Int
}

struct AdminAppointmentList: Codable {
    let content: [AdminBooking]
    let totalElements: Int
    let totalPages: Int
    let number: Int
    let size: Int
}

// MARK: - ViewModel
@MainActor
class AdminViewModel: ObservableObject {
    @Published var dashboard: DashboardData?
    @Published var appointments: [AdminBooking] = []
    @Published var artists: [Artist] = []
    @Published var services: [SalonService] = []
    @Published var revenueReport: RevenueReport?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var totalAppointments = 0
    @Published var currentPage = 0

    func loadDashboard() async {
        isLoading = true
        do {
            let response: ApiResponse<DashboardData> = try await APIClient.shared.get("/admin/dashboard")
            dashboard = response.data
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadAppointments(date: Date? = nil, status: String? = nil, page: Int = 0) async {
        isLoading = true
        var endpoint = "/admin/appointments?page=\(page)&size=20"
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            endpoint += "&date=\(formatter.string(from: date))"
        }
        if let status = status, !status.isEmpty {
            endpoint += "&status=\(status)"
        }
        do {
            let response: ApiResponse<AdminAppointmentList> = try await APIClient.shared.get(endpoint)
            if let data = response.data {
                if page == 0 {
                    appointments = data.content
                } else {
                    appointments.append(contentsOf: data.content)
                }
                totalAppointments = data.totalElements
                currentPage = page
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateAppointmentStatus(id: String, status: String) async {
        struct StatusBody: Codable { let status: String }

        // Update locally immediately for instant UI feedback
        if let index = appointments.firstIndex(where: { $0.id == id }) {
            let old = appointments[index]
            appointments[index] = AdminBooking(
                id: old.id, artist: old.artist, service: old.service,
                startTime: old.startTime, endTime: old.endTime, status: status,
                user: old.user, appointmentDate: old.appointmentDate,
                bookingRef: old.bookingRef, originalPrice: old.originalPrice,
                finalPrice: old.finalPrice
            )
        }

        do {
            let _: ApiResponse<AdminBooking> = try await APIClient.shared.put(
                "/admin/appointments/\(id)/status",
                body: StatusBody(status: status)
            )
            // Reload from server to sync
            await loadAppointments()
            await loadDashboard()
        } catch {
            errorMessage = error.localizedDescription
            // Revert on failure
            await loadAppointments()
        }
    }

    func loadArtists() async {
        do {
            let response: ApiResponse<[Artist]> = try await APIClient.shared.get("/admin/artists")
            artists = response.data ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadServices() async {
        do {
            let response: ApiResponse<[SalonService]> = try await APIClient.shared.get("/admin/services")
            services = response.data ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadRevenueReport(startDate: Date? = nil, endDate: Date? = nil) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let start = formatter.string(from: startDate ?? Date().addingTimeInterval(-30 * 24 * 3600))
        let end = formatter.string(from: endDate ?? Date())
        do {
            let response: ApiResponse<RevenueReport> = try await APIClient.shared.get(
                "/admin/reports/revenue?startDate=\(start)&endDate=\(end)"
            )
            revenueReport = response.data
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteArtist(id: String) async {
        do {
            let _: ApiResponse<String> = try await APIClient.shared.delete("/admin/artists/\(id)")
            await loadArtists()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteService(id: String) async {
        do {
            let _: ApiResponse<String> = try await APIClient.shared.delete("/admin/services/\(id)")
            await loadServices()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
