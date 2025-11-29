import SwiftUI
import Combine

@MainActor
final class HomeDailyTasksViewModel: ObservableObject {
    let userId: Int?

    @Published var calendarInfo: CalendarInfoResponse?
    @Published var dailyPlan: DailyTaskPlanResponse?
    @Published var isLoading: Bool = true
    @Published var loadError: String?

    @Published var dailyFortune: DailyFortuneResponse?
    @Published var isFortuneLoading: Bool = false
    @Published var fortuneError: String?
    
    // MARK: - Fortune Cache Keys
    private static let fortuneCacheKey = "cached_daily_fortune"
    private static let fortuneCacheDateKey = "cached_daily_fortune_date"

    @Published var goalPlans: [GoalPlanResponse] = []
    @Published var isGoalPlanLoading: Bool = false
    @Published var goalPlanError: String?
    
    /// Flag to track if goal data needs refresh (set when updates are made)
    @Published var goalDataNeedsRefresh: Bool = false
    
    @Published var showGoalWizard: Bool = false
    @Published var goalWizardSource: String? = "manual"
    
    @Published var weeklyCompletion: [DailyCompletionItem] = []
    @Published var isWeeklyCompletionLoading: Bool = false
    
    /// Expired milestones that need user attention
    @Published var expiredMilestones: [ExpiredMilestoneInfo] = []
    @Published var showExpiredMilestoneDialog: Bool = false
    
    /// Returns yesterday's task completion summary message
    var yesterdaySummaryMessage: String? {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let yesterdayString = dateFormatter.string(from: yesterday)
        
        guard let yesterdayData = weeklyCompletion.first(where: { $0.date == yesterdayString }) else {
            return nil
        }
        
        // No tasks yesterday
        if yesterdayData.totalTasks == 0 {
            return nil
        }
        
        // All tasks completed
        if yesterdayData.completedTasks == yesterdayData.totalTasks {
            return "昨天很棒！完成了所有任务呢🎉，今天继续加油🚀！"
        }
        
        // Some tasks not completed
        return "昨天有部分任务没完成呢😞，今天要加油哦💪！"
    }

    init(userId: Int?) {
        self.userId = userId
    }

    /// Returns tasks that are planned/in_progress AND belong to active goals
    var visibleTasks: [DailyTaskItemResponse] {
        guard let items = dailyPlan?.items else { return [] }
        let activeGoalIds = Set(goalPlans.filter { $0.status == "active" }.map { $0.goalId })
        return items.filter { item in
            (item.status == "planned" || item.status == "in_progress") &&
            activeGoalIds.contains(item.goalId)
        }
    }
    
    /// Returns true if tasks were assigned today but all have been completed/cancelled
    var allTasksCompleted: Bool {
        guard let items = dailyPlan?.items, !items.isEmpty else { return false }
        let activeGoalIds = Set(goalPlans.filter { $0.status == "active" }.map { $0.goalId })
        let tasksForActiveGoals = items.filter { activeGoalIds.contains($0.goalId) }
        // If there are tasks for active goals but none are pending, all are completed
        return !tasksForActiveGoals.isEmpty && visibleTasks.isEmpty
    }

    /// Returns only active goals
    var activeGoalPlans: [GoalPlanResponse] {
        goalPlans.filter { $0.status == "active" }
    }

    func loadInitialDataIfNeeded() {
        guard isLoading else { return }
        
        // Load cached fortune immediately (synchronous)
        loadCachedFortuneIfAvailable()

        Task {
            // Track start time for minimum splash duration
            let startTime = Date()
            
            await fetchCalendarAndPlan()
            // Also load goal plans so visibleTasks can filter properly
            await loadGoalPlanIfNeeded()
            // Fetch weekly completion for calendar widget
            await loadWeeklyCompletion()
            
            // Ensure splash shows for at least 2 seconds
            let elapsed = Date().timeIntervalSince(startTime)
            let minimumDuration: TimeInterval = 2.0
            if elapsed < minimumDuration {
                try? await Task.sleep(nanoseconds: UInt64((minimumDuration - elapsed) * 1_000_000_000))
            }
            
            // Now set isLoading to false to dismiss splash
            isLoading = false
        }
    }

    private func fetchCalendarAndPlan() async {
        loadError = nil

        do {
            let calendar = try await CalendarAPI.shared.fetchTodayCalendar()
            calendarInfo = calendar
        } catch {
            print("❌ fetchTodayCalendar error:", error)
            loadError = "日历信息加载失败，请检查网络后稍后再试。"
        }

        do {
            guard let userId else {
                loadError = "系统暂时无法获取你的账户信息，今日待办暂时无法加载，请稍后再试。"
                return
            }

            // Use new ExecutionsAPI.fetchDailyPlan which auto-expires overdue milestones
            let plan = try await ExecutionsAPI.shared.fetchDailyPlan(userId: userId)
            dailyPlan = plan
            
            // Handle expired milestones if any
            print("📋 Daily plan received. Expired milestones: \(plan.expiredMilestones?.count ?? 0)")
            if let expired = plan.expiredMilestones, !expired.isEmpty {
                print("⚠️ Found \(expired.count) expired milestones, showing dialog")
                expiredMilestones = expired
                showExpiredMilestoneDialog = true
            }
        } catch {
            print("❌ fetchDailyPlan error:", error)
            loadError = "暂时无法获取今日待办事项，请稍后再试。"
        }
    }

    func loadGoalPlanIfNeeded(forceReload: Bool = false) async {
        guard !isGoalPlanLoading else { return }
        
        // Skip if already loaded and not forcing reload
        if !forceReload && !goalPlans.isEmpty { return }

        guard let userId else {
            goalPlanError = "系统暂时无法获取你的账户信息，目标计划暂时无法加载，请稍后再试。"
            return
        }

        isGoalPlanLoading = true
        goalPlanError = nil

        do {
            let response = try await GoalsAPI.shared.fetchUserGoalsPlans(userId: userId)
            goalPlans = response.goals
        } catch {
            print("❌ loadGoalPlanIfNeeded error:", error)
            goalPlanError = "暂时无法获取目标计划，请稍后再试。"
        }

        isGoalPlanLoading = false
    }

    /// Load cached fortune from UserDefaults if it's for today
    func loadCachedFortuneIfAvailable() {
        let today = todayDateString()
        
        // Check if cached fortune is for today
        guard let cachedDate = UserDefaults.standard.string(forKey: Self.fortuneCacheDateKey),
              cachedDate == today,
              let cachedData = UserDefaults.standard.data(forKey: Self.fortuneCacheKey) else {
            // No valid cache for today
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let fortune = try decoder.decode(DailyFortuneResponse.self, from: cachedData)
            dailyFortune = fortune
            print("✅ Loaded cached fortune for today")
        } catch {
            print("❌ Failed to decode cached fortune:", error)
            // Clear invalid cache
            clearFortuneCache()
        }
    }
    
    /// Save fortune to UserDefaults cache
    private func cacheFortuneData(_ fortune: DailyFortuneResponse) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(fortune)
            UserDefaults.standard.set(data, forKey: Self.fortuneCacheKey)
            UserDefaults.standard.set(fortune.context.solarDate, forKey: Self.fortuneCacheDateKey)
            print("✅ Cached fortune for date:", fortune.context.solarDate)
        } catch {
            print("❌ Failed to cache fortune:", error)
        }
    }
    
    /// Clear fortune cache
    private func clearFortuneCache() {
        UserDefaults.standard.removeObject(forKey: Self.fortuneCacheKey)
        UserDefaults.standard.removeObject(forKey: Self.fortuneCacheDateKey)
    }
    
    /// Get today's date string in yyyy-MM-dd format
    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    /// Fetch daily fortune from backend (backend persists result for the day)
    func loadDailyFortuneIfNeeded() async {
        guard !isFortuneLoading else { return }
        
        // If we already have fortune loaded this session, skip
        if dailyFortune != nil {
            return
        }

        guard let userId else {
            fortuneError = "系统暂时无法获取你的账户信息，今日运势暂时无法加载，请稍后再试。"
            return
        }

        isFortuneLoading = true
        fortuneError = nil

        do {
            // Backend returns persisted fortune for today if already generated
            let response = try await FortuneAPI.shared.fetchDailyFortune(userId: userId)
            dailyFortune = response
            // Cache the fortune for today
            cacheFortuneData(response)
        } catch {
            print("❌ fetchDailyFortune error:", error)
            fortuneError = "暂时无法获取今日运势，请稍后再试。"
        }

        isFortuneLoading = false
    }

    func reloadPlanOnly() async {
        do {
            guard let userId else { return }
            let plan = try await ExecutionsAPI.shared.fetchDailyPlan(userId: userId)
            dailyPlan = plan
            
            // Handle expired milestones if any
            if let expired = plan.expiredMilestones, !expired.isEmpty {
                expiredMilestones = expired
                showExpiredMilestoneDialog = true
            }
        } catch {
            print("❌ reloadPlanOnly error:", error)
            // actionError is owned by the view; surface a generic message here if needed.
        }
    }
    
    /// Load weekly completion data for calendar widget (current week: Mon-Sun)
    func loadWeeklyCompletion() async {
        guard !isWeeklyCompletionLoading else { return }
        guard let userId else { return }
        
        isWeeklyCompletionLoading = true
        
        // Calculate current week's Monday and Sunday
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        // weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        // We want Monday as start of week
        let daysFromMonday = (weekday + 5) % 7 // 0 for Monday, 6 for Sunday
        
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today),
              let sunday = calendar.date(byAdding: .day, value: 6 - daysFromMonday, to: today) else {
            isWeeklyCompletionLoading = false
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let startDate = formatter.string(from: monday)
        let endDate = formatter.string(from: sunday)
        
        do {
            let response = try await ExecutionsAPI.shared.getCalendarCompletion(
                userId: userId,
                startDate: startDate,
                endDate: endDate
            )
            weeklyCompletion = response.days
        } catch {
            print("❌ loadWeeklyCompletion error:", error)
            // Silently fail - widget will show empty state
        }
        
        isWeeklyCompletionLoading = false
    }
    
    /// Assign tasks for today by calling the daily plan API
    /// This generates TaskExecution records for the user's active goals
    func assignTodayTasks() async {
        guard let userId else {
            print("❌ assignTodayTasks: No userId available")
            return
        }
        
        do {
            // Calling fetchDailyPlan will generate task executions if they don't exist
            let plan = try await ExecutionsAPI.shared.fetchDailyPlan(userId: userId)
            dailyPlan = plan
            print("✅ Tasks assigned for today, count:", plan.items.count)
            
            // Handle expired milestones if any
            if let expired = plan.expiredMilestones, !expired.isEmpty {
                expiredMilestones = expired
                showExpiredMilestoneDialog = true
            }
        } catch {
            print("❌ assignTodayTasks error:", error)
            loadError = "任务分配失败，请稍后再试。"
        }
    }
}
