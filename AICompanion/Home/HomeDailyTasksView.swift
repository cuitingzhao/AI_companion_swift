import SwiftUI

public struct HomeDailyTasksView: View {
    private let userId: Int?
    @StateObject private var viewModel: HomeDailyTasksViewModel
    @StateObject private var chatViewModel: ChatViewModel
    @State private var isUpdatingExecution: Bool = false
    @State private var actionError: String?
    @State private var selectedTaskForDetail: DailyTaskItemResponse?
    @State private var selectedTab: Tab = .daily
    @State private var isShowingChat: Bool = false
    @State private var isAssigningTasks: Bool = false
    
    // Confirmation dialog state (for full-screen mask)
    @State private var showCompleteConfirmation: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var taskForConfirmation: DailyTaskItemResponse?

    public init(userId: Int?) {
        self.userId = userId
        let uid = userId ?? 0
        _viewModel = StateObject(wrappedValue: HomeDailyTasksViewModel(userId: userId))
        _chatViewModel = StateObject(wrappedValue: ChatViewModel(userId: uid))
    }

    public var body: some View {
        ZStack {
            AppColors.accentYellow
                .ignoresSafeArea()

            // Image("star_bg")
            //     .resizable()
            //     .scaledToFill()
            //     .ignoresSafeArea()
            //     .opacity(0.5)

            VStack(spacing: 0) {
                // Finch-inspired: Transparent header (no background)
                currentHeaderView
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                // Content area with sage green background
                ZStack {
                    // Sage green content background
                    AppColors.gradientBackground
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
                                    hasActiveGoals: !viewModel.activeGoalPlans.isEmpty,
                                    isAssigningTasks: isAssigningTasks,
                                    allTasksCompleted: viewModel.allTasksCompleted,
                                    weeklyCompletion: viewModel.weeklyCompletion,
                                    onTaskTapped: { task in
                                        selectedTaskForDetail = task
                                    },
                                    onQuickComplete: { task in
                                        handleExecutionAction(.complete, for: task)
                                    },
                                    onAssignTasks: {
                                        isAssigningTasks = true
                                        Task {
                                            await viewModel.assignTodayTasks()
                                            isAssigningTasks = false
                                        }
                                    },
                                    onRequestComplete: { task in
                                        taskForConfirmation = task
                                        showCompleteConfirmation = true
                                    }
                                )
                            case .goals:
                                GoalTrackingPageView(
                                    plans: viewModel.activeGoalPlans,
                                    dailyTasks: viewModel.dailyPlan?.items ?? [],
                                    isLoading: viewModel.isGoalPlanLoading,
                                    errorText: viewModel.goalPlanError,
                                    onAddGoal: {
                                        viewModel.goalWizardSource = "manual"
                                        viewModel.showGoalWizard = true
                                    }
                                )
                            case .fortune, .personality, .settings:
                                placeholderSection(for: selectedTab)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                // .clipShape(
                //     RoundedCorner(radius: CuteClean.radiusLarge, corners: [.topLeft, .topRight])
                // )

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

                GeometryReader { geometry in
                    VStack {
                        Spacer()
                        TaskExecutionCardView(
                            task: selectedTask,
                            width: geometry.size.width * 0.82,
                            onAction: { action in
                                handleExecutionAction(action, for: selectedTask)
                                selectedTaskForDetail = nil
                            },
                            onRequestComplete: {
                                taskForConfirmation = selectedTask
                                showCompleteConfirmation = true
                                selectedTaskForDetail = nil
                            },
                            onRequestDelete: {
                                taskForConfirmation = selectedTask
                                showDeleteConfirmation = true
                                selectedTaskForDetail = nil
                            }
                        )
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }

            // Floating mascot chat button (hidden on Goals tab)
            if selectedTab != .goals {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            isShowingChat = true
                        }) {
                            VStack(spacing: 4) {
                                GIFImage(name: "singing")
                                    .frame(width: 120, height: 120)
                                    .allowsHitTesting(false)
                                Text("点我聊天")
                                    .font(AppFonts.caption)
                                    .foregroundStyle(AppColors.textMedium)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 24)
                        .padding(.bottom, 100)
                    }
                }
            }
            
            // Full-screen confirmation dialogs
            AppDialog(
                isPresented: $showCompleteConfirmation,
                message: "确定要完成「\(taskForConfirmation?.title ?? "")」吗？",
                primaryTitle: "确认完成",
                primaryAction: {
                    if let task = taskForConfirmation {
                        handleExecutionAction(.complete, for: task)
                    }
                    showCompleteConfirmation = false
                    taskForConfirmation = nil
                },
                secondaryTitle: "取消",
                secondaryAction: {
                    showCompleteConfirmation = false
                    taskForConfirmation = nil
                },
                title: "完成任务"
            )
            
            AppDialog(
                isPresented: $showDeleteConfirmation,
                message: "确定要删除「\(taskForConfirmation?.title ?? "")」吗？删除后无法恢复。",
                primaryTitle: "确认删除",
                primaryAction: {
                    if let task = taskForConfirmation {
                        handleExecutionAction(.cancel, for: task)
                    }
                    showDeleteConfirmation = false
                    taskForConfirmation = nil
                },
                secondaryTitle: "取消",
                secondaryAction: {
                    showDeleteConfirmation = false
                    taskForConfirmation = nil
                },
                title: "删除任务"
            )
        }
        .fullScreenCover(isPresented: $isShowingChat) {
            ChatView(viewModel: chatViewModel)
        }
        .fullScreenCover(isPresented: $viewModel.showGoalWizard) {
            if let userId = userId {
                GoalWizardView(
                    userId: userId,
                    candidateDescription: nil,
                    source: viewModel.goalWizardSource,
                    onDismiss: {
                        viewModel.showGoalWizard = false
                        // Reload goal plans after wizard closes
                        Task {
                            viewModel.goalPlans = []
                            await viewModel.loadGoalPlanIfNeeded()
                        }
                    }
                )
            }
        }
        .onAppear {
            viewModel.loadInitialDataIfNeeded()
            // Pre-warm chat data in background for faster chat opening
            chatViewModel.prewarm()
        }
        .onChange(of: selectedTab) { _, newTab in
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

    // Time-based greeting
    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "早上好"
        case 12..<14:
            return "中午好"
        case 14..<18:
            return "下午好"
        default:
            return "晚上好"
        }
    }
    
    // Get nickname from UserDefaults
    private var userNickname: String {
        UserDefaults.standard.string(forKey: "onboarding.nickname") ?? ""
    }
    
    private var headerView: some View {
        let info = viewModel.calendarInfo
        let fortune = viewModel.dailyFortune

        return VStack(alignment: .leading, spacing: 12) {
            // Greeting title
            Text("\(timeBasedGreeting)，\(userNickname)")
                .font(AppFonts.large)
                .foregroundStyle(AppColors.textBlack)
            
            // Yesterday's task summary
            if let summaryMessage = viewModel.yesterdaySummaryMessage {
                Text(summaryMessage)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textMedium)
            }
            
            // Date subtitle
            if let info {
                Text("\(formattedSolarDate(info.solarDate))｜农历\(info.lunarDate)")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textMedium)
            }
            
            // Fortune guide container
            VStack(spacing: 12) {
                if let fortune, fortune.color != nil || fortune.food != nil || fortune.direction != nil {
                    // Show fortune data
                    HStack(alignment: .top, spacing: 16) {
                        if let color = fortune.color {
                            fortuneInfoItem(icon: "paintpalette.fill", label: "幸运颜色", value: color)
                        }
                        if let food = fortune.food {
                            fortuneInfoItem(icon: "leaf.fill", label: "幸运食材", value: food)
                        }
                        if let direction = fortune.direction {
                            fortuneInfoItem(icon: "location.north.fill", label: "幸运方位", value: direction)
                        }
                    }
                } else {
                    // Show button to fetch fortune
                    Button(action: {
                        Task {
                            await viewModel.loadDailyFortuneIfNeeded()
                        }
                    }) {
                        HStack(spacing: 8) {
                            if viewModel.isFortuneLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(AppColors.primary)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            Text("点击获取今日提运指南")
                                .font(AppFonts.cuteButton)
                        }
                        .foregroundStyle(AppColors.primary)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isFortuneLoading)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(AppColors.cardWhite)
            .cornerRadius(CuteClean.radiusMedium)
            .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
    }
    
    private func fortuneInfoItem(icon: String, label: String, value: String) -> some View {
        // Split comma-separated values into separate lines
        let values = value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        return VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.primary)
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textLight)
            VStack(spacing: 2) {
                ForEach(values, id: \.self) { item in
                    Text(item)
                        .font(AppFonts.small)
                        .foregroundStyle(AppColors.textBlack)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var goalTrackingHeaderView: some View {
        // No header needed for goal tracking tab - content speaks for itself
        EmptyView()
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

    // MARK: - Bottom Tab Bar (Finch-Inspired)

    private var bottomTabBar: some View {
        HStack(spacing: 8) {
            bottomTabItem(icon: "checkmark.circle.fill", label: "每日待办", tab: .daily)
            bottomTabItem(icon: "target", label: "目标追踪", tab: .goals)
            // Hidden for now - feature not ready
            // bottomTabItem(icon: "sparkles", label: "流年推测", tab: .fortune)
            // bottomTabItem(icon: "person.crop.circle", label: "性格密码", tab: .personality)
            bottomTabItem(icon: "gearshape.fill", label: "设置", tab: .settings)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(AppColors.cardWhite)
        .shadow(color: AppColors.shadowColor, radius: 6, x: 0, y: -2)
    }

    private func bottomTabItem(icon: String, label: String, tab: Tab) -> some View {
        let isActive = selectedTab == tab

        return Button(action: {
            withAnimation(.easeOut(duration: CuteClean.animationQuick)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(isActive ? AppColors.primary : AppColors.textMedium)

                Text(label)
                    .font(AppFonts.caption)
                    .foregroundStyle(isActive ? AppColors.primary : AppColors.textLight)
                
                // Finch-style pill indicator
                Capsule()
                    .fill(isActive ? AppColors.primary : Color.clear)
                    .frame(width: 24, height: 4)
                    .offset(y: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
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
