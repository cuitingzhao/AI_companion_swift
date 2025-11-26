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

    @Published var goalPlans: [GoalPlanResponse] = []
    @Published var isGoalPlanLoading: Bool = false
    @Published var goalPlanError: String?

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

    /// Returns only active goals
    var activeGoalPlans: [GoalPlanResponse] {
        goalPlans.filter { $0.status == "active" }
    }

    func loadInitialDataIfNeeded() {
        guard isLoading else { return }

        Task {
            await fetchCalendarAndPlan()
        }
    }

    private func fetchCalendarAndPlan() async {
        isLoading = true
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

            let plan = try await GoalsAPI.shared.fetchTodayPlan(userId: userId)
            dailyPlan = plan
        } catch {
            print("❌ fetchTodayPlan error:", error)
            loadError = "暂时无法获取今日待办事项，请稍后再试。"
        }

        isLoading = false
    }

    func loadGoalPlanIfNeeded() async {
        guard !isGoalPlanLoading else { return }
        guard goalPlans.isEmpty else { return }

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

    func loadDailyFortuneIfNeeded() async {
        guard !isFortuneLoading else { return }

        guard let userId else {
            fortuneError = "系统暂时无法获取你的账户信息，今日运势暂时无法加载，请稍后再试。"
            return
        }

        isFortuneLoading = true
        fortuneError = nil

        do {
            let response = try await FortuneAPI.shared.fetchDailyFortune(userId: userId)
            dailyFortune = response
        } catch {
            print("❌ fetchDailyFortune error:", error)
            fortuneError = "暂时无法获取今日运势，请稍后再试。"
        }

        isFortuneLoading = false
    }

    func reloadPlanOnly() async {
        do {
            guard let userId else { return }
            let plan = try await GoalsAPI.shared.fetchTodayPlan(userId: userId)
            dailyPlan = plan
        } catch {
            print("❌ reloadPlanOnly error:", error)
            // actionError is owned by the view; surface a generic message here if needed.
        }
    }
}
