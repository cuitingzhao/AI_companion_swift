import Foundation

// MARK: - Goal Onboarding Message

public struct GoalOnboardingMessageRequest: Codable {
    public let userId: Int
    public let message: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case message
    }
}

public struct GoalOnboardingMessageResponse: Codable {
    public let reply: String
    public let stage: String
    public let goalCompleted: Bool
    public let goalId: Int?

    enum CodingKeys: String, CodingKey {
        case reply
        case stage
        case goalCompleted = "goal_completed"
        case goalId = "goal_id"
    }
}

// MARK: - Goal Onboarding Skip

public struct GoalOnboardingSkipRequest: Codable {
    public let userId: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

public struct GoalOnboardingSkipResponse: Codable {
    public let status: String
    public let message: String
}

// MARK: - Goal Onboarding Status (for potential future use)

public struct GoalOnboardingStatusResponse: Codable {
    public let stage: String
    public let goalId: Int?
    public let goalSummary: String?
    public let milestonesCount: Int
    public let tasksCount: Int

    enum CodingKeys: String, CodingKey {
        case stage
        case goalId = "goal_id"
        case goalSummary = "goal_summary"
        case milestonesCount = "milestones_count"
        case tasksCount = "tasks_count"
    }
}

// MARK: - Goal Plan

public struct GoalPlanTask: Codable {
    public let id: Int
    public let title: String
    public let desc: String?
    public let dueAt: String?
    public let estimatedMinutes: Int?
    public let frequency: String
    public let status: String
    public let priority: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case desc
        case dueAt = "due_at"
        case estimatedMinutes = "estimated_minutes"
        case frequency
        case status
        case priority
    }
}

public struct GoalPlanMilestone: Codable {
    public let id: Int
    public let title: String
    public let desc: String?
    public let startDate: String?
    public let dueDate: String?
    public let priority: String
    public let status: String
    public let tasks: [GoalPlanTask]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case desc
        case startDate = "start_date"
        case dueDate = "due_date"
        case priority
        case status
        case tasks
    }
}

public struct GoalPlanResponse: Codable {
    public let goalId: Int
    public let title: String
    public let desc: String?
    public let dueDate: String?
    public let dailyMinutes: Int?
    public let motivation: String?
    public let constraints: String?
    public let progress: Int
    public let status: String
    public let milestones: [GoalPlanMilestone]

    enum CodingKeys: String, CodingKey {
        case goalId = "goal_id"
        case title
        case desc
        case dueDate = "due_date"
        case dailyMinutes = "daily_minutes"
        case motivation
        case constraints
        case progress
        case status
        case milestones
    }
}
