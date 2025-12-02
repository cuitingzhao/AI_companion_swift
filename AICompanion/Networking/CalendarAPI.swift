import Foundation

/// Calendar API - Utility endpoints (no auth required)
@MainActor
public final class CalendarAPI {
    public static let shared = CalendarAPI()
    private let client = APIClient.shared
    
    private init() {}
    
    public func fetchTodayCalendar(tz: String? = nil) async throws -> CalendarInfoResponse {
        var path = "/api/v1/utils/calendar/today"
        if let tz = tz {
            path += "?tz=\(tz)"
        }
        return try await client.get(path: path, requiresAuth: false)
    }
}
