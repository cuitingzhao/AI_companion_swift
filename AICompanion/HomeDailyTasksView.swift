import SwiftUI

public struct HomeDailyTasksView: View {
    private let userId: Int?
    @StateObject private var viewModel: HomeDailyTasksViewModel
    @State private var isUpdatingExecution: Bool = false
    @State private var actionError: String?
    @State private var selectedTaskForDetail: DailyTaskItemResponse?
    @State private var isShowingFortuneCard: Bool = false
    @State private var isFortuneGlowActive: Bool = false
    @State private var selectedTab: Tab = .daily

    public init(userId: Int?) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: HomeDailyTasksViewModel(userId: userId))
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
                currentHeaderView
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 16)

                ZStack {
                    AppColors.lavender.opacity(0.9)
                        .ignoresSafeArea(edges: .bottom)

                    ScrollView {
                        VStack(spacing: 24) {
                            switch selectedTab {
                            case .daily:
                                DailyTasksPageView(
                                    loadError: viewModel.loadError,
                                    isLoading: viewModel.isLoading,
                                    tasks: viewModel.visibleTasks,
                                    actionError: actionError,
                                    onTaskTapped: { task in
                                        selectedTaskForDetail = task
                                    },
                                    onQuickComplete: { task in
                                        handleExecutionAction(.complete, for: task)
                                    }
                                )
                            case .goals:
                                GoalTrackingPageView(
                                    plans: viewModel.goalPlans,
                                    isLoading: viewModel.isGoalPlanLoading,
                                    errorText: viewModel.goalPlanError
                                )
                            case .fortune, .personality, .settings:
                                placeholderSection(for: selectedTab)
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

            if isShowingFortuneCard {
                Color.black.opacity(0.24)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isShowingFortuneCard = false
                    }

                VStack {
                    DailyFortuneCardView(
                        isLoading: viewModel.isFortuneLoading,
                        fortune: viewModel.dailyFortune,
                        errorText: viewModel.fortuneError
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
        }
        .onAppear(perform: viewModel.loadInitialDataIfNeeded)
        .onChange(of: selectedTab) { newTab in
            switch newTab {
            case .goals:
                Task {
                    await viewModel.loadGoalPlanIfNeeded()
                }
            case .daily:
                Task {
                    await viewModel.reloadPlanOnly()
                }
            default:
                break
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var currentHeaderView: some View {
        switch selectedTab {
        case .daily:
            headerView
        case .goals:
            goalTrackingHeaderView
        case .fortune, .personality, .settings:
            headerView
        }
    }

    private var headerView: some View {
        let info = viewModel.calendarInfo

        return HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
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

            Spacer(minLength: 12)

            fortuneHeaderIcon
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    private var goalTrackingHeaderView: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("目标追踪")
                    .font(AppFonts.large)
                    .foregroundStyle(AppColors.textBlack)

                Text("查看你的长期目标和关键里程碑")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.neutralGray)
            }

            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var fortuneHeaderIcon: some View {
        let symbol: String? = viewModel.dailyFortune?.fortuneLevel
        let outerColor = fortuneOuterColor(for: symbol)

        Button {
            isShowingFortuneCard = true

            if viewModel.dailyFortune == nil {
                Task {
                    await viewModel.loadDailyFortuneIfNeeded()
                }
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    if symbol == nil {
                        Circle()
                            .stroke(AppColors.lavender.opacity(0.65), lineWidth: 5)
                            .frame(width: 92, height: 92)
                            .scaleEffect(isFortuneGlowActive ? 1.06 : 0.92)
                            .blur(radius: 4)
                            .animation(
                                .easeInOut(duration: 1.1)
                                    .repeatForever(autoreverses: true),
                                value: isFortuneGlowActive
                            )

                        Image("fortune_wheel_small")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 84, height: 84)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 6)
                    } else {
                        Circle()
                            .fill(outerColor)
                            .frame(width: 84, height: 84)
                            .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 6)
                    }

                    Circle()
                        .stroke(AppColors.white, lineWidth: 2)
                        .frame(width: 72, height: 72)

                    if let symbol {
                        Text(symbol)
                            .font(AppFonts.subtitle)
                            .foregroundStyle(AppColors.white)
                    }
                }

                if symbol == nil {
                    VStack(spacing: 2) {
                        Text("点击查看")
                            .font(AppFonts.caption)
                        Text("今日运势")
                            .font(AppFonts.caption)
                    }
                    .foregroundStyle(AppColors.purple)
                }
            }
        }
        .buttonStyle(.plain)
        .offset(y: -8)
        .onAppear {
            if !isFortuneGlowActive {
                isFortuneGlowActive = true
            }
        }
    }

    @ViewBuilder
    private var dailyTabSection: some View {
        EmptyView()
    }

    @ViewBuilder
    private var goalTrackingSection: some View {
        EmptyView()
    }

    @ViewBuilder
    private func placeholderSection(for tab: Tab) -> some View {
        switch tab {
        case .fortune:
            Text("流年推测功能即将上线")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.neutralGray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 40)
        case .personality:
            Text("性格密码功能即将上线")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.neutralGray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 40)
        case .settings:
            Text("设置功能即将上线")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.neutralGray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 40)
        case .daily, .goals:
            EmptyView()
        }
    }

    // MARK: - Bottom Tab Bar

    private var bottomTabBar: some View {
        HStack(spacing: 12) {
            bottomTabItem(icon: "checkmark.circle.fill", label: "每日待办", tab: .daily)
            bottomTabItem(icon: "target", label: "目标追踪", tab: .goals)
            bottomTabItem(icon: "sparkles", label: "流年推测", tab: .fortune)
            bottomTabItem(icon: "person.crop.circle", label: "性格密码", tab: .personality)
            bottomTabItem(icon: "gearshape", label: "设置", tab: .settings)
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(
            Color.white.opacity(0.95)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func bottomTabItem(icon: String, label: String, tab: Tab) -> some View {
        let isActive = selectedTab == tab

        return Button(action: {
            selectedTab = tab
        }) {
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
        .buttonStyle(.plain)
    }

    // MARK: - Data Loading

    // MARK: - Execution Actions

    enum ExecutionAction {
        case complete
        case cancel
        case postpone
    }

    private enum Tab {
        case daily
        case goals
        case fortune
        case personality
        case settings
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

                await viewModel.reloadPlanOnly()
            } catch {
                print("❌ updateExecution error:", error)
                actionError = "更新待办事项状态失败，请稍后重试。"
            }

            isUpdatingExecution = false
        }
    }

    // MARK: - Helpers

    private func fortuneOuterColor(for symbol: String?) -> Color {
        switch symbol {
        case "吉":
            return AppColors.gold
        case "平":
            return AppColors.jade
        case "凶":
            return AppColors.textBlack
        default:
            return AppColors.white.opacity(0.9)
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

#Preview {
    HomeDailyTasksView(userId: 1)
}
