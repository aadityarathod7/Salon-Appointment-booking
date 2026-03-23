import Foundation

@MainActor
class ArtistViewModel: ObservableObject {
    @Published var artists: [Artist] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadArtists() async {
        isLoading = true
        do {
            let response: ApiResponse<[Artist]> = try await APIClient.shared.get("/artists", authenticated: false)
            artists = response.data ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadArtistsForService(serviceId: String) async {
        isLoading = true
        do {
            let response: ApiResponse<[Artist]> = try await APIClient.shared.get("/services/\(serviceId)/artists", authenticated: false)
            artists = response.data ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
