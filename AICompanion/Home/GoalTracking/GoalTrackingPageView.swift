import SwiftUI

// MARK: - Finch-Inspired Goal Tracking Page
struct GoalTrackingPageView: View {
    let plans: [GoalPlanResponse]
    let dailyTasks: [DailyTaskItemResponse]
    let isLoading: Bool
    let errorText: String?
    let onAddGoal: () -> Void
    var onGoalUpdated: (() -> Void)?
    
    @State private var selectedGoalId: Int?

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 16) {
                // Header row with dropdown only
                if plans.count > 1 {
                    HStack(spacing: 12) {
                        goalDropdown
                        Spacer()
                    }
                }
                
                GoalTrackingSectionView(
                    plan: selectedPlan,
                    currentMilestoneIds: currentMilestoneIdsForSelectedGoal,
                    isLoading: isLoading,
                    errorText: errorText,
                    onGoalUpdated: onGoalUpdated
                )
                
                // Bottom spacing for floating button
                Spacer()
                    .frame(height: 80)
            }
            
            // Floating Add Goal Button at bottom center
            Button(action: onAddGoal) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                    Text("创建新目标")
                        .font(AppFonts.cuteLabel)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    ZStack {
                        // Depth layer
                        RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                            .fill(AppColors.primaryDepth)
                            .offset(y: 4)
                        // Main face
                        RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                            .fill(AppColors.primary)
                    }
                )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 16)
        }
        .onAppear {
            // Select first goal by default
            if selectedGoalId == nil, let firstPlan = plans.first {
                selectedGoalId = firstPlan.goalId
            }
        }
        .onChange(of: plans.map { $0.goalId }) { _ in
            // Update selection if current selection is no longer valid
            if let currentId = selectedGoalId,
               !plans.contains(where: { $0.goalId == currentId }),
               let firstPlan = plans.first {
                selectedGoalId = firstPlan.goalId
            } else if selectedGoalId == nil, let firstPlan = plans.first {
                selectedGoalId = firstPlan.goalId
            }
        }
    }
    
    private var selectedPlan: GoalPlanResponse? {
        guard let selectedGoalId else { return plans.first }
        return plans.first { $0.goalId == selectedGoalId }
    }
    
    /// Get milestone IDs that have tasks assigned today for the selected goal
    private var currentMilestoneIdsForSelectedGoal: Set<Int> {
        guard let goalId = selectedGoalId ?? plans.first?.goalId else { return [] }
        let milestoneIds = dailyTasks
            .filter { $0.goalId == goalId && $0.milestoneId != nil }
            .compactMap { $0.milestoneId }
        return Set(milestoneIds)
    }
    
    private var goalDropdown: some View {
        Menu {
            ForEach(plans, id: \.goalId) { plan in
                Button(action: {
                    selectedGoalId = plan.goalId
                }) {
                    HStack {
                        Text(plan.title)
                        if plan.goalId == selectedGoalId {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(selectedPlan?.title ?? "选择目标")
                    .font(AppFonts.cuteLabel)
                    .foregroundStyle(AppColors.textBlack)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.textMedium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppColors.cardWhite)
            .cornerRadius(CuteClean.radiusMedium)
            .shadow(color: AppColors.shadowColor, radius: 2, x: 0, y: 1)
        }
    }
}

#Preview {
    GoalTrackingPageView(
        plans: [],
        dailyTasks: [],
        isLoading: false,
        errorText: nil,
        onAddGoal: {}
    )
    .padding()
}
