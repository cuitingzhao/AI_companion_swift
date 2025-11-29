import SwiftUI

struct GoalTrackingSectionView: View {
    let plan: GoalPlanResponse?
    let currentMilestoneIds: Set<Int>
    let isLoading: Bool
    let errorText: String?
    var onGoalUpdated: (() -> Void)?
    
    @StateObject private var viewModel = GoalTrackingViewModel()
    
    // Computed property to use local plan if available, otherwise use passed plan
    private var displayPlan: GoalPlanResponse? {
        viewModel.displayPlan(from: plan)
    }

    var body: some View {
        if isLoading {
            loadingView
        } else if let errorText {
            errorView(errorText)
        } else if let currentPlan = displayPlan {
            contentView(plan: currentPlan)
        } else {
            emptyView
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(AppColors.purple)
            Text("正在为你加载目标计划，请稍候…")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textBlack)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 40)
    }
    
    // MARK: - Error View
    
    private func errorView(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.body)
            .foregroundStyle(AppColors.accentRed)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 40)
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        Text("目标计划尚未生成")
            .font(AppFonts.body)
            .foregroundStyle(AppColors.neutralGray)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Content View
    
    private func contentView(plan: GoalPlanResponse) -> some View {
        ZStack {
            VStack(alignment: .leading, spacing: 16) {
                goalTrackingHeader(plan: plan)
                
                MilestoneTimelineView(
                    plan: plan,
                    currentMilestoneIds: currentMilestoneIds,
                    onEditMilestone: { milestone in
                        viewModel.selectedMilestone = milestone
                        viewModel.showMilestoneEditDialog = true
                    },
                    onEditTask: { task in
                        viewModel.selectedTask = task
                        viewModel.showTaskEditDialog = true
                    }
                )
            }
            .padding(.horizontal, 4)
            
            // Edit dialogs
            editDialogs(plan: plan)
            
            // Toast overlay
            toastOverlay
        }
        .onChange(of: plan.goalId) { _ in
            viewModel.resetLocalPlan()
        }
        .onAppear {
            viewModel.onGoalUpdated = onGoalUpdated
        }
    }
    
    // MARK: - Goal Header
    
    private func goalTrackingHeader(plan: GoalPlanResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text("目标")
                    .font(AppFonts.large)
                    .foregroundStyle(AppColors.textBlack)

                Spacer()
                
                // Edit button
                Button(action: { viewModel.showGoalEditDialog = true }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.textMedium)
                        .padding(8)
                        .background(AppColors.neutralGray.opacity(0.3))
                        .cornerRadius(8)
                }
            }

            Text(plan.title)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textBlack)
                .fixedSize(horizontal: false, vertical: true)
            
            if let due = plan.dueDate, !due.isEmpty {
                Text("截止日期：\(due)")
                    .font(AppFonts.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColors.textBlack)
                    .cornerRadius(14)
            }
        }
    }
    
    // MARK: - Edit Dialogs
    
    @ViewBuilder
    private func editDialogs(plan: GoalPlanResponse) -> some View {
        if viewModel.showGoalEditDialog {
            GoalEditDialog(
                isPresented: $viewModel.showGoalEditDialog,
                goal: plan,
                onSave: { request in
                    viewModel.applyGoalUpdate(request: request, currentPlan: displayPlan)
                    await viewModel.updateGoalAPI(goalId: plan.goalId, request: request)
                },
                onSuccess: { message in
                    viewModel.showToastMessage(message)
                }
            )
        }
        
        if viewModel.showMilestoneEditDialog, let milestone = viewModel.selectedMilestone {
            MilestoneEditDialog(
                isPresented: $viewModel.showMilestoneEditDialog,
                milestone: milestone,
                onSave: { request in
                    viewModel.applyMilestoneUpdate(milestoneId: milestone.id, request: request, currentPlan: displayPlan)
                    await viewModel.updateMilestoneAPI(milestoneId: milestone.id, request: request)
                },
                onSuccess: { message in
                    viewModel.showToastMessage(message)
                }
            )
        }
        
        if viewModel.showTaskEditDialog, let task = viewModel.selectedTask {
            TaskEditDialog(
                isPresented: $viewModel.showTaskEditDialog,
                task: task,
                onSave: { request in
                    viewModel.applyTaskUpdate(taskId: task.id, request: request, currentPlan: displayPlan)
                    await viewModel.updateTaskAPI(taskId: task.id, request: request)
                },
                onSuccess: { message in
                    viewModel.showToastMessage(message)
                }
            )
        }
    }
    
    // MARK: - Toast Overlay
    
    @ViewBuilder
    private var toastOverlay: some View {
        if viewModel.showToast, let message = viewModel.toastMessage {
            VStack {
                Spacer()
                Text(message)
                    .font(AppFonts.body)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.textBlack.opacity(0.85))
                    .cornerRadius(20)
                Spacer()
            }
            .transition(.opacity)
            .zIndex(100)
        }
    }
}
