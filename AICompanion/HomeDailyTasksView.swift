import SwiftUI

public struct HomeDailyTasksView: View {
    private let userId: Int?

    @State private var calendarInfo: CalendarInfoResponse?
    @State private var dailyPlan: DailyTaskPlanResponse?
    @State private var isLoading: Bool = true
    @State private var loadError: String?
    @State private var isUpdatingExecution: Bool = false
    @State private var actionError: String?
    @State private var selectedTaskForDetail: DailyTaskItemResponse?

    public init(userId: Int?) {
        self.userId = userId
    }

    private var visibleTasks: [DailyTaskItemResponse] {
        guard let items = dailyPlan?.items else { return [] }
        return items.filter { item in
            item.status == "planned" || item.status == "in_progress"
        }
    }

    public var body: some View {
        ZStack {
            AppColors.gradientBackground
                .ignoresSafeArea()

            Image("star_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.5)

            VStack(spacing: 0) {
                headerView
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 16)

                ZStack {
                    AppColors.lavender.opacity(0.9)
                        .ignoresSafeArea(edges: .bottom)

                    ScrollView {
                        VStack(spacing: 24) {
                            if let error = loadError {
                                Text(error)
                                    .font(AppFonts.caption)
                                    .foregroundStyle(AppColors.accentRed)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            if isLoading {
                                ProgressView()
                                    .tint(AppColors.purple)
                                    .padding(.top, 40)
                            } else {
                                tasksSection
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }.padding(.horizontal, 24)

                bottomTabBar
            }

            if isUpdatingExecution {
                Color.black.opacity(0.18)
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    ProgressView()
                        .tint(AppColors.purple)

                    Text("正在更新待办事项状态，请稍候")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textBlack)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(Color.white)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 6)
            }

            if let selectedTask = selectedTaskForDetail {
                Color.black.opacity(0.18)
                    .ignoresSafeArea()
                    .onTapGesture {
                        selectedTaskForDetail = nil
                    }

                VStack {
                    TaskExecutionCardView(
                        task: selectedTask,
                        width: UIScreen.main.bounds.width * 0.82,
                        onAction: { action in
                            handleExecutionAction(action, for: selectedTask)
                            selectedTaskForDetail = nil
                        }
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
        .onAppear(perform: loadInitialDataIfNeeded)
    }

    // MARK: - Header

    private var headerView: some View {
        let info = calendarInfo

        return VStack(alignment: .leading, spacing: 8) {
            if let info {
                Text(formattedSolarDate(info.solarDate))
                    .font(AppFonts.large)
                    .foregroundStyle(AppColors.textBlack)

                Text("农历: \(info.lunarDate)")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.neutralGray)

                if let current = info.currentJieqi, !current.isEmpty {
                    Text("当前节气：\(current)")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.neutralGray)
                }

                if let next = info.nextJieqi {
                    if let days = daysUntil(next.solarDate, from: info.solarDate), days > 0 {
                        Text("下一个节气：\(next.name)（还有\(days)天）")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.neutralGray)
                    } else {
                        Text("下一个节气：\(next.name)（就在今天）")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.neutralGray)
                    }
                }
            } else {
                Text("今日运势与日程")
                    .font(AppFonts.large)
                    .foregroundStyle(AppColors.textBlack)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    // MARK: - Tasks Section

    @ViewBuilder
    private var tasksSection: some View {
        let tasks: [DailyTaskItemResponse] = visibleTasks

        if tasks.isEmpty {
            emptyTasksCard
        } else {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.white)

                    Text("今天还有\(tasks.count)个小任务待完成")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.white)
                }

                VStack(spacing: 12) {
                    ForEach(Array(tasks.enumerated()), id: \.element.executionId) { _, item in
                        let iconColor = priorityColor(for: item.priority)

                        HStack(spacing: 12) {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(iconColor.opacity(0.85))
                                    .frame(width: 6, height: 6)

                                Circle()
                                    .fill(iconColor.opacity(0.85))
                                    .frame(width: 6, height: 6)

                                Circle()
                                    .fill(iconColor.opacity(0.85))
                                    .frame(width: 6, height: 6)
                            }
                            .frame(width: 12)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(AppFonts.small)
                                    .foregroundStyle(AppColors.textBlack)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

                                if let minutes = item.estimatedMinutes {
                                    Text("预计用时：\(minutes) 分钟")
                                        .font(AppFonts.caption)
                                        .foregroundStyle(AppColors.neutralGray)
                                }
                            }

                            Spacer(minLength: 8)

                            Button(action: {
                                handleExecutionAction(.complete, for: item)
                            }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Color.white)
                                    .frame(width: 38, height: 38)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                AppColors.accentGreen,
                                                AppColors.accentGreen.opacity(0.85)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .clipShape(Circle())
                                    .shadow(color: AppColors.accentGreen.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTaskForDetail = item
                        }
                    }
                }

                if let actionError {
                    Text(actionError)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.accentRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var emptyTasksCard: some View {
        let cardWidth = UIScreen.main.bounds.width * 0.82

        return HStack {
            Spacer()

            VStack(spacing: 0) {
                Text("今日待办")
                    .font(AppFonts.small)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppColors.purple)

                VStack {
                    Spacer()

                    Text("今天还没有为你安排任何待办事项，\n可以适当休息一下啦。")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textBlack)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(16)
            }
            .frame(width: cardWidth, height: 280)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)

            Spacer()
        }
    }

    // MARK: - Bottom Tab Bar

    private var bottomTabBar: some View {
        HStack(spacing: 12) {
            bottomTabItem(icon: "checkmark.circle.fill", label: "每日待办", isActive: true)
            bottomTabItem(icon: "target", label: "目标追踪", isActive: false)
            bottomTabItem(icon: "sparkles", label: "流年推测", isActive: false)
            bottomTabItem(icon: "person.crop.circle", label: "性格密码", isActive: false)
            bottomTabItem(icon: "gearshape", label: "设置", isActive: false)
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(
            Color.white.opacity(0.95)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func bottomTabItem(icon: String, label: String, isActive: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isActive ? Color.white : AppColors.purple.opacity(0.55))
                .frame(width: 32, height: 32)
                .background(isActive ? AppColors.purple : Color.clear)
                .clipShape(Circle())

            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(isActive ? AppColors.purple : AppColors.neutralGray)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Data Loading

    private func loadInitialDataIfNeeded() {
        guard isLoading else { return }

        Task {
            await fetchCalendarAndPlan()
        }
    }

    @MainActor
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

    @MainActor
    private func reloadPlanOnly() async {
        do {
            guard let userId else { return }
            let plan = try await GoalsAPI.shared.fetchTodayPlan(userId: userId)
            dailyPlan = plan
        } catch {
            print("❌ reloadPlanOnly error:", error)
            actionError = "刷新待办事项列表失败，请稍后再试一次。"
        }
    }

    // MARK: - Execution Actions

    enum ExecutionAction {
        case complete
        case cancel
        case postpone
    }

    private func handleExecutionAction(_ action: ExecutionAction, for task: DailyTaskItemResponse) {
        guard !isUpdatingExecution else { return }

        if action == .postpone && (task.frequency == "daily" || task.frequency == "weekdays") {
            actionError = "该待办事项为每日/工作日重复事项，目前不支持推迟。"
            return
        }

        isUpdatingExecution = true
        actionError = nil

        Task {
            do {
                let request: ExecutionUpdateRequest

                switch action {
                case .complete:
                    request = ExecutionUpdateRequest(action: "complete")
                case .cancel:
                    request = ExecutionUpdateRequest(action: "cancel")
                case .postpone:
                    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    let newDate = formatter.string(from: tomorrow)
                    request = ExecutionUpdateRequest(action: "postpone", newDate: newDate)
                }

                _ = try await ExecutionsAPI.shared.updateExecution(executionId: task.executionId, request: request)

                await reloadPlanOnly()
            } catch {
                print("❌ updateExecution error:", error)
                actionError = "更新待办事项状态失败，请稍后重试。"
            }

            isUpdatingExecution = false
        }
    }

    // MARK: - Helpers

    private func priorityColor(for priority: String) -> Color {
        switch priority {
        case "high":
            return AppColors.accentRed
        case "medium":
            return AppColors.textBlack
        default:
            return AppColors.neutralGray
        }
    }

    private func formattedSolarDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let output = DateFormatter()
        output.locale = Locale(identifier: "zh_CN")
        output.dateFormat = "yyyy年M月d日"
        return output.string(from: date)
    }

    private func daysUntil(_ targetDateString: String, from baseDateString: String) -> Int? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard
            let baseDate = formatter.date(from: baseDateString),
            let targetDate = formatter.date(from: targetDateString)
        else {
            return nil
        }

        let calendar = Calendar.current
        let startOfBase = calendar.startOfDay(for: baseDate)
        let startOfTarget = calendar.startOfDay(for: targetDate)
        let components = calendar.dateComponents([.day], from: startOfBase, to: startOfTarget)
        return components.day
    }
}

private struct TaskExecutionCardView: View {
    let task: DailyTaskItemResponse
    let width: CGFloat
    let onAction: (HomeDailyTasksView.ExecutionAction) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(task.goalTitle ?? "今日待办")
                .font(AppFonts.small)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppColors.lavender)

            VStack(spacing: 16) {
                Text(task.title)
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textBlack)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let minutes = task.estimatedMinutes {
                    Text("预计用时：\(minutes) 分钟")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.neutralGray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 32) {
                    actionButton(color: .red, systemImage: "minus", label: "删除") {
                        onAction(.cancel)
                    }

                    actionButton(color: .green, systemImage: "checkmark", label: "完成") {
                        onAction(.complete)
                    }

                    let canPostpone = !(task.frequency == "daily" || task.frequency == "weekdays")

                    actionButton(color: .yellow, systemImage: "clock", label: "推迟", disabled: !canPostpone) {
                        if canPostpone {
                            onAction(.postpone)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
        .frame(width: width, height: 320, alignment: .top)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)
    }

    private func actionButton(color: Color, systemImage: String, label: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        VStack(spacing: 6) {
            Button(action: action) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 40, height: 40)
                    .background(disabled ? AppColors.neutralGray.opacity(0.4) : color)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(disabled)

            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textBlack)
        }
    }
}

#Preview {
    HomeDailyTasksView(userId: 1)
}
