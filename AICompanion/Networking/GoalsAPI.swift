import Foundation

/// Goals API - All endpoints require authentication
@MainActor
public final class GoalsAPI {
    public static let shared = GoalsAPI()
    private let client = APIClient.shared
    
    private init() {}
    
    // MARK: - Goal Onboarding
    
    public func sendOnboardingMessage(_ request: GoalOnboardingMessageRequest) async throws -> GoalOnboardingMessageResponse {
        try await client.post(path: "/api/v1/goals/onboarding/message", body: request)
    }
    
    public func skipOnboarding(_ request: GoalOnboardingSkipRequest) async throws -> GoalOnboardingSkipResponse {
        try await client.post(path: "/api/v1/goals/onboarding/skip", body: request)
    }
    
    /// GET /api/v1/goals/onboarding/status
    public func fetchOnboardingStatus() async throws -> GoalOnboardingStatusResponse {
        return try await client.get(path: "/api/v1/goals/onboarding/status")
    }
    
    // MARK: - Goal Plans
    
    /// GET /api/v1/goals/{goal_id}/plan
    public func fetchGoalPlan(goalId: Int) async throws -> GoalPlanResponse {
        return try await client.get(path: "/api/v1/goals/\(goalId)/plan")
    }
    
    /// GET /api/v1/goals/plans
    public func fetchAllGoalsPlans() async throws -> UserGoalsPlansResponse {
        return try await client.get(path: "/api/v1/goals/plans")
    }
    
    /// GET /api/v1/users/today-plan
    public func fetchTodayPlan() async throws -> DailyTaskPlanResponse {
        return try await client.get(path: "/api/v1/users/today-plan")
    }
    
    // MARK: - Deprecated
    
    @available(*, deprecated, message: "Use fetchOnboardingStatus() - userId derived from token")
    public func fetchOnboardingStatus(userId: Int) async throws -> GoalOnboardingStatusResponse {
        return try await fetchOnboardingStatus()
    }
    
    @available(*, deprecated, message: "Use fetchAllGoalsPlans() - userId derived from token")
    public func fetchUserGoalsPlans(userId: Int) async throws -> UserGoalsPlansResponse {
        return try await fetchAllGoalsPlans()
    }
    
    @available(*, deprecated, message: "Use fetchTodayPlan() - userId derived from token")
    public func fetchTodayPlan(userId: Int) async throws -> DailyTaskPlanResponse {
        return try await fetchTodayPlan()
    }
    
    // MARK: - Update Goal
    
    public func updateGoal(goalId: Int, request: GoalUpdateRequest) async throws -> GoalUpdateResponse {
        return try await client.patch(path: "/api/v1/goals/\(goalId)", body: request)
    }
    
    // MARK: - Update Milestone
    
    public func updateMilestone(milestoneId: Int, request: MilestoneUpdateRequest) async throws -> MilestoneUpdateResponse {
        return try await client.patch(path: "/api/v1/goals/milestones/\(milestoneId)/fields", body: request)
    }
    
    public func performMilestoneAction(milestoneId: Int, request: MilestoneActionRequest) async throws -> MilestoneActionResponse {
        return try await client.patch(path: "/api/v1/goals/milestones/\(milestoneId)", body: request)
    }
    
    // MARK: - Update Task
    
    public func updateTask(taskId: Int, request: TaskUpdateRequest) async throws -> TaskUpdateResponse {
        return try await client.patch(path: "/api/v1/goals/tasks/\(taskId)", body: request)
    }
}
