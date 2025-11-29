import Foundation

@MainActor
public final class GoalsAPI {
    public static let shared = GoalsAPI()
    public let baseURL: URL

    public init(baseURL: URL = URL(string: "http://localhost:8000")!) {
        self.baseURL = baseURL
    }

    public func sendOnboardingMessage(_ request: GoalOnboardingMessageRequest) async throws -> GoalOnboardingMessageResponse {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/goals/onboarding/message"

        guard let url = components.url else {
            throw OnboardingAPIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw OnboardingAPIError.badResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(GoalOnboardingMessageResponse.self, from: data)
    }

    public func skipOnboarding(_ request: GoalOnboardingSkipRequest) async throws -> GoalOnboardingSkipResponse {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/goals/onboarding/skip"

        guard let url = components.url else {
            throw OnboardingAPIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw OnboardingAPIError.badResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(GoalOnboardingSkipResponse.self, from: data)
    }

    public func fetchOnboardingStatus(userId: Int) async throws -> GoalOnboardingStatusResponse {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/goals/onboarding/status/\(userId)"

        guard let url = components.url else {
            throw OnboardingAPIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw OnboardingAPIError.badResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(GoalOnboardingStatusResponse.self, from: data)
    }

    public func fetchGoalPlan(goalId: Int) async throws -> GoalPlanResponse {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/goals/\(goalId)/plan"

        guard let url = components.url else {
            throw OnboardingAPIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw OnboardingAPIError.badResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(GoalPlanResponse.self, from: data)
    }

    public func fetchUserGoalsPlans(userId: Int) async throws -> UserGoalsPlansResponse {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/goals/user/\(userId)/plans"

        guard let url = components.url else {
            throw OnboardingAPIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw OnboardingAPIError.badResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(UserGoalsPlansResponse.self, from: data)
    }

    public func fetchTodayPlan(userId: Int) async throws -> DailyTaskPlanResponse {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/users/\(userId)/today-plan"

        guard let url = components.url else {
            throw OnboardingAPIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw OnboardingAPIError.badResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(DailyTaskPlanResponse.self, from: data)
    }
    
    // MARK: - Update Goal
    
    public func updateGoal(goalId: Int, request: GoalUpdateRequest) async throws -> GoalUpdateResponse {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/goals/\(goalId)"
        
        guard let url = components.url else {
            throw OnboardingAPIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PATCH"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw OnboardingAPIError.badResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(GoalUpdateResponse.self, from: data)
    }
    
    // MARK: - Update Milestone
    
    public func updateMilestone(milestoneId: Int, request: MilestoneUpdateRequest) async throws -> MilestoneUpdateResponse {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/goals/milestones/\(milestoneId)/fields"
        
        guard let url = components.url else {
            throw OnboardingAPIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PATCH"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw OnboardingAPIError.badResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(MilestoneUpdateResponse.self, from: data)
    }
    
    // MARK: - Milestone Action (complete/expire/reopen)
    
    public func performMilestoneAction(milestoneId: Int, request: MilestoneActionRequest) async throws -> MilestoneActionResponse {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/goals/milestones/\(milestoneId)"
        
        guard let url = components.url else {
            throw OnboardingAPIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PATCH"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw OnboardingAPIError.badResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(MilestoneActionResponse.self, from: data)
    }
    
    // MARK: - Update Task
    
    public func updateTask(taskId: Int, request: TaskUpdateRequest) async throws -> TaskUpdateResponse {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/goals/tasks/\(taskId)"
        
        guard let url = components.url else {
            throw OnboardingAPIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PATCH"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw OnboardingAPIError.badResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(TaskUpdateResponse.self, from: data)
    }
}
