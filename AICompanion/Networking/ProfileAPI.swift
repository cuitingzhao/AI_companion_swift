import Foundation

/// Profile API - All endpoints require authentication
@MainActor
public final class ProfileAPI {
    public static let shared = ProfileAPI()
    private let client = APIClient.shared
    
    private init() {}
    
    /// POST /api/v1/profile/location
    public func updateLocation(_ request: LocationUpdateRequest) async throws -> LocationUpdateResponse {
        return try await client.post(path: "/api/v1/profile/location", body: request)
    }
    
    /// GET /api/v1/profile/location
    public func getLocation() async throws -> LocationUpdateResponse {
        return try await client.get(path: "/api/v1/profile/location")
    }
    
    // MARK: - Deprecated
    
    @available(*, deprecated, message: "Use getLocation() - userId derived from token")
    public func getLocation(userId: Int) async throws -> LocationUpdateResponse {
        return try await getLocation()
    }
}
