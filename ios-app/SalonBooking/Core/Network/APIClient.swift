import Foundation

extension Notification.Name {
    static let userSessionExpired = Notification.Name("userSessionExpired")
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .unauthorized: return "Session expired. Please login again."
        case .serverError(let message): return message
        case .decodingError(let error): return "Data error: \(error.localizedDescription)"
        case .networkError(let error): return error.localizedDescription
        }
    }
}

class APIClient {
    static let shared = APIClient()

    private let baseURL = "http://localhost:8080/api/v1"
    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()

    private init() {}

    // MARK: - Generic Request

    func request<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: (any Codable)? = nil,
        authenticated: Bool = true
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authenticated, let token = TokenManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            if httpResponse.statusCode == 401 {
                // Try to refresh token
                if authenticated {
                    let refreshed = try await refreshToken()
                    if refreshed {
                        return try await self.request(
                            endpoint: endpoint,
                            method: method,
                            body: body,
                            authenticated: authenticated
                        )
                    }
                }
                // Refresh failed — clear tokens so AuthManager detects logout
                TokenManager.shared.clearTokens()
                NotificationCenter.default.post(name: .userSessionExpired, object: nil)
                throw APIError.unauthorized
            }

            if httpResponse.statusCode >= 400 {
                if let errorResponse = try? decoder.decode(ApiResponse<String>.self, from: data) {
                    throw APIError.serverError(errorResponse.message ?? "Unknown error")
                }
                throw APIError.serverError("Server error (\(httpResponse.statusCode))")
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Convenience Methods

    func get<T: Codable>(_ endpoint: String, authenticated: Bool = true) async throws -> ApiResponse<T> {
        return try await request(endpoint: endpoint, authenticated: authenticated)
    }

    func post<T: Codable>(_ endpoint: String, body: any Codable, authenticated: Bool = true) async throws -> ApiResponse<T> {
        return try await request(endpoint: endpoint, method: "POST", body: body, authenticated: authenticated)
    }

    func put<T: Codable>(_ endpoint: String, body: (any Codable)? = nil, authenticated: Bool = true) async throws -> ApiResponse<T> {
        return try await request(endpoint: endpoint, method: "PUT", body: body, authenticated: authenticated)
    }

    func delete(_ endpoint: String) async throws -> ApiResponse<String> {
        return try await request(endpoint: endpoint, method: "DELETE")
    }

    // MARK: - Token Refresh

    private func refreshToken() async throws -> Bool {
        guard let refreshToken = TokenManager.shared.refreshToken else { return false }

        struct RefreshBody: Codable { let refreshToken: String }

        let response: ApiResponse<AuthResponse> = try await request(
            endpoint: "/auth/refresh",
            method: "POST",
            body: RefreshBody(refreshToken: refreshToken),
            authenticated: false
        )

        if let auth = response.data {
            TokenManager.shared.saveTokens(
                accessToken: auth.accessToken,
                refreshToken: auth.refreshToken
            )
            return true
        }
        return false
    }
}
