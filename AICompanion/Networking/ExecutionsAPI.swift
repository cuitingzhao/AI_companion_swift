import Foundation

/// Executions API - All endpoints require authentication
@MainActor
public final class ExecutionsAPI {
    public static let shared = ExecutionsAPI()
    private let client = APIClient.shared
    
    private init() {}
    
    public func updateExecution(executionId: Int, request: ExecutionUpdateRequest) async throws -> ExecutionUpdateResponse {
        try await client.patch(path: "/api/v1/executions/\(executionId)", body: request)
    }
    
    /// GET /api/v1/executions/daily
    /// Fetch daily task plan with auto-expiration of overdue milestones
    public func fetchDailyPlan(targetDate: String? = nil) async throws -> DailyTaskPlanResponse {
        var path = "/api/v1/executions/daily"
        if let targetDate = targetDate {
            path += "?target_date=\(targetDate)"
        }
        return try await client.get(path: path)
    }
    
    /// GET /api/v1/executions/calendar/completion
    public func getCalendarCompletion(startDate: String, endDate: String) async throws -> CalendarCompletionResponse {
        let path = "/api/v1/executions/calendar/completion?start_date=\(startDate)&end_date=\(endDate)"
        return try await client.get(path: path)
    }
    
    // MARK: - Deprecated
    
    @available(*, deprecated, message: "Use fetchDailyPlan(targetDate:) - userId derived from token")
    public func fetchDailyPlan(userId: Int, targetDate: String? = nil) async throws -> DailyTaskPlanResponse {
        return try await fetchDailyPlan(targetDate: targetDate)
    }
    
    @available(*, deprecated, message: "Use getCalendarCompletion(startDate:endDate:) - userId derived from token")
    public func getCalendarCompletion(userId: Int, startDate: String, endDate: String) async throws -> CalendarCompletionResponse {
        return try await getCalendarCompletion(startDate: startDate, endDate: endDate)
    }
}
