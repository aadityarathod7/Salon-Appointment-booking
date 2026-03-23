import Foundation

@MainActor
class ServiceViewModel: ObservableObject {
    @Published var services: [SalonService] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadServices(category: String? = nil) async {
        isLoading = true
        do {
            let endpoint = category != nil ? "/services?category=\(category!)" : "/services"
            let response: ApiResponse<[SalonService]> = try await APIClient.shared.get(endpoint, authenticated: false)
            services = response.data ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
