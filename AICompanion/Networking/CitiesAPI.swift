import Foundation

/// Cities API - NO AUTH REQUIRED (public utility endpoint)
@MainActor
public final class CitiesAPI {
    public static let shared = CitiesAPI()
    private let client = APIClient.shared
    
    private init() {}
    
    public func searchCities(query: String, limit: Int = 10) async throws -> [City] {
        var path = "/api/v1/utils/cities?limit=\(limit)"
        if !query.isEmpty {
            path += "&q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
        }
        let response: CityListResponse = try await client.get(path: path, requiresAuth: false)
        return response.cities
    }
}
