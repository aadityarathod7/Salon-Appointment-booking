import Foundation

@MainActor
class AppointmentViewModel: ObservableObject {
    @Published var appointments: [Appointment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTab = "UPCOMING"

    func loadAppointments() async {
        isLoading = true
        do {
            let response: ApiResponse<PaginatedResponse<Appointment>> = try await APIClient.shared.get(
                "/appointments?status=\(selectedTab)&page=0&size=20"
            )
            appointments = response.data?.content ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func cancelAppointment(id: String) async {
        do {
            struct CancelBody: Codable { let reason: String? }
            let _: ApiResponse<Appointment> = try await APIClient.shared.put(
                "/appointments/\(id)/cancel",
                body: CancelBody(reason: nil)
            )
            await loadAppointments()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
