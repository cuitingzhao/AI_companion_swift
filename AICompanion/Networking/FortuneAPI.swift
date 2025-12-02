import Foundation

/// Fortune API - All endpoints require authentication
@MainActor
public final class FortuneAPI {
    public static let shared = FortuneAPI()
    private let client = APIClient.shared
    
    private init() {}
    
    public func fetchDailyFortune(tz: String? = nil) async throws -> DailyFortuneResponse {
        var path = "/api/v1/fortune/daily"
        if let tz = tz {
            path += "?tz=\(tz)"
        }
        return try await client.get(path: path)
    }
    
    public func fetchYearlyFortune() async throws -> YearlyFortuneResponse {
        try await client.get(path: "/api/v1/fortune/yearly")
    }
    
    // MARK: - Deprecated (use methods without userId)
    
    @available(*, deprecated, message: "Use fetchDailyFortune(tz:) instead - userId is now derived from token")
    public func fetchDailyFortune(userId: Int, tz: String? = nil) async throws -> DailyFortuneResponse {
        try await fetchDailyFortune(tz: tz)
    }
}

/// Yearly fortune response placeholder
public struct YearlyFortuneResponse: Codable {
    // TODO: Define fields based on API response
}
