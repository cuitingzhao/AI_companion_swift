import SwiftUI

public struct HomeDailyTasksView: View {
    private let userId: Int?
    @StateObject private var viewModel: HomeDailyTasksViewModel
    @StateObject private var chatViewModel: ChatViewModel
    @State private var isUpdatingExecution: Bool = false
    @State private var actionError: String?
    @State private var selectedTaskForDetail: DailyTaskItemResponse?
    @State private var selectedTab: HomeTab = .daily
    @State private var isShowingChat: Bool = false
    @State private var isAssigningTasks: Bool = false
    
    // Confirmation dialog state (for full-screen mask)
    @State private var showCompleteConfirmation: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var taskForConfirmation: DailyTaskItemResponse?
    
    // Celebration effect state
    @State private var showCelebration: Bool = false

    public init(userId: Int?) {
        self.userId = userId
        let uid = userId ?? 0
        _viewModel = StateObject(wrappedValue: HomeDailyTasksViewModel(userId: userId))
        _chatViewModel = StateObject(wrappedValue: ChatViewModel(userId: uid))
    }

    public var body: some View {
        ZStack {
            // Show splash screen during initial loading
            if viewModel.isLoading {
                SplashView()
            } else {
                mainContent
            }
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
                    // If data needs refresh (updates were made), reload goal plans
                    if viewModel.goalDataNeedsRefresh {
                        await viewModel.loadGoalPlanIfNeeded(forceReload: true)
                        viewModel.goalDataNeedsRefresh = false
                    } else {
                        await viewModel.loadGoalPlanIfNeeded()
                    }
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
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ZStack {
            AppColors.accentYellow
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header view based on selected tab
                if selectedTab == .daily {
                    HomeHeaderView(
                        calendarInfo: viewModel.calendarInfo,
                        dailyFortune: viewModel.dailyFortune,
                        yesterdaySummaryMessage: viewModel.yesterdaySummaryMessage,
                        isFortuneLoading: viewModel.isFortuneLoading,
                        onLoadFortune: {
                            Task {
                                await viewModel.loadDailyFortuneIfNeeded()
                            }
                        }
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }

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
                                    },
                                    onGoalUpdated: {
                                        // Mark data as needing refresh for when user switches tabs
                                        viewModel.goalDataNeedsRefresh = true
                                        Task {
                                            await viewModel.reloadPlanOnly()
                                        }
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

                HomeBottomTabBar(selectedTab: $selectedTab)
            }

            // Task execution overlay (loading + detail card + confirmations)
            TaskExecutionOverlay(
                selectedTask: selectedTaskForDetail,
                isUpdating: isUpdatingExecution,
                showCompleteConfirmation: $showCompleteConfirmation,
                showDeleteConfirmation: $showDeleteConfirmation,
                taskForConfirmation: $taskForConfirmation,
                onDismiss: { selectedTaskForDetail = nil },
                onAction: { action, task in
                    handleExecutionAction(action, for: task)
                }
            )

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
            
            // Celebration overlay
            CelebrationOverlay(isShowing: $showCelebration)
            
            // Expired milestone wizard
            if viewModel.showExpiredMilestoneDialog {
                ExpiredMilestoneWizardView(
                    isPresented: $viewModel.showExpiredMilestoneDialog,
                    expiredMilestones: viewModel.expiredMilestones,
                    onComplete: {
                        // Reload data after handling expired milestones
                        Task {
                            await viewModel.reloadPlanOnly()
                            await viewModel.loadGoalPlanIfNeeded(forceReload: true)
                        }
                    }
                )
            }
        }
    }

    // MARK: - Placeholder Sections

    @ViewBuilder
    private func placeholderSection(for tab: HomeTab) -> some View {
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

    // MARK: - Execution Actions

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

                // Show celebration effect on task completion
                if action == .complete {
                    withAnimation {
                        showCelebration = true
                    }
                }
                
                await viewModel.reloadPlanOnly()
            } catch {
                print("❌ updateExecution error:", error)
                actionError = "更新待办事项状态失败，请稍后重试。"
            }

            isUpdatingExecution = false
        }
    }

}

#Preview {
    HomeDailyTasksView(userId: 1)
}
