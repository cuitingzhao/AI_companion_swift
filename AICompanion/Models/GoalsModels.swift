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

public struct UserGoalsPlansResponse: Codable {
    public let userId: Int
    public let goals: [GoalPlanResponse]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case goals
    }
}

public struct DailyTaskItemResponse: Codable {
    public let executionId: Int
    public let taskId: Int
    public let goalId: Int
    public let goalTitle: String?
    public let milestoneId: Int?
    public let title: String
    public let estimatedMinutes: Int?
    public let priority: String
    public let frequency: String
    public let status: String
    public let plannedDate: String
    public let executionDate: String?

    enum CodingKeys: String, CodingKey {
        case executionId = "execution_id"
        case taskId = "task_id"
        case goalId = "goal_id"
        case goalTitle = "goal_title"
        case milestoneId = "milestone_id"
        case title
        case estimatedMinutes = "estimated_minutes"
        case priority
        case frequency
        case status
        case plannedDate = "planned_date"
        case executionDate = "execution_date"
    }
}

// MARK: - Expired Milestone Info

public struct ExpiredMilestoneInfo: Codable {
    public let milestoneId: Int
    public let title: String
    public let goalId: Int
    public let goalTitle: String?
    public let dueDate: String?
    
    enum CodingKeys: String, CodingKey {
        case milestoneId = "milestone_id"
        case title
        case goalId = "goal_id"
        case goalTitle = "goal_title"
        case dueDate = "due_date"
    }
}

public struct DailyTaskPlanResponse: Codable {
    public let date: String
    public let items: [DailyTaskItemResponse]
    public let expiredMilestones: [ExpiredMilestoneInfo]?
    
    enum CodingKeys: String, CodingKey {
        case date
        case items
        case expiredMilestones = "expired_milestones"
    }
}

public struct ExecutionUpdateRequest: Codable {
    public let action: String
    public let newDate: String?
    public let actualMinutes: Int?
    public let note: String?

    enum CodingKeys: String, CodingKey {
        case action
        case newDate = "new_date"
        case actualMinutes = "actual_minutes"
        case note
    }

    public init(action: String, newDate: String? = nil, actualMinutes: Int? = nil, note: String? = nil) {
        self.action = action
        self.newDate = newDate
        self.actualMinutes = actualMinutes
        self.note = note
    }
}

public struct ExecutionUpdateResponse: Codable {
    public let status: String
    public let message: String
}

// MARK: - Calendar Completion

public struct DailyCompletionItem: Codable {
    public let date: String
    public let totalTasks: Int
    public let completedTasks: Int
    public let completionRate: Double

    enum CodingKeys: String, CodingKey {
        case date
        case totalTasks = "total_tasks"
        case completedTasks = "completed_tasks"
        case completionRate = "completion_rate"
    }
}

public struct CalendarCompletionResponse: Codable {
    public let userId: Int
    public let startDate: String
    public let endDate: String
    public let days: [DailyCompletionItem]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case days
    }
}

// MARK: - Goal Update

public struct GoalUpdateRequest: Codable {
    public let title: String?
    public let status: String?
    public let dueDate: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case status
        case dueDate = "due_date"
    }
    
    public init(title: String? = nil, status: String? = nil, dueDate: String? = nil) {
        self.title = title
        self.status = status
        self.dueDate = dueDate
    }
}

public struct GoalUpdateResponse: Codable {
    public let status: String
    public let message: String
    public let updatedFields: [String]
    
    enum CodingKeys: String, CodingKey {
        case status
        case message
        case updatedFields = "updated_fields"
    }
}

// MARK: - Milestone Update

public struct MilestoneUpdateRequest: Codable {
    public let title: String?
    public let desc: String?
    public let dueDate: String?
    public let priority: String?
    public let status: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case desc
        case dueDate = "due_date"
        case priority
        case status
    }
    
    public init(title: String? = nil, desc: String? = nil, dueDate: String? = nil, priority: String? = nil, status: String? = nil) {
        self.title = title
        self.desc = desc
        self.dueDate = dueDate
        self.priority = priority
        self.status = status
    }
}

public struct MilestoneUpdateResponse: Codable {
    public let status: String
    public let message: String
    public let updatedFields: [String]
    
    enum CodingKeys: String, CodingKey {
        case status
        case message
        case updatedFields = "updated_fields"
    }
}

// MARK: - Milestone Action (complete/expire/reopen)

public struct MilestoneActionRequest: Codable {
    public let action: String
    public let newDueDate: String?
    
    enum CodingKeys: String, CodingKey {
        case action
        case newDueDate = "new_due_date"
    }
    
    public init(action: String, newDueDate: String? = nil) {
        self.action = action
        self.newDueDate = newDueDate
    }
}

public struct MilestoneActionResponse: Codable {
    public let status: String
    public let message: String
}

// MARK: - Task Update

public struct TaskUpdateRequest: Codable {
    public let title: String?
    public let status: String?
    public let priority: String?
    public let frequency: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case status
        case priority
        case frequency
    }
    
    public init(title: String? = nil, status: String? = nil, priority: String? = nil, frequency: String? = nil) {
        self.title = title
        self.status = status
        self.priority = priority
        self.frequency = frequency
    }
}

public struct TaskUpdateResponse: Codable {
    public let status: String
    public let message: String
    public let updatedFields: [String]
    
    enum CodingKeys: String, CodingKey {
        case status
        case message
        case updatedFields = "updated_fields"
    }
}
