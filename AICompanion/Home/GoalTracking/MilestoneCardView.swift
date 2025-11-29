import SwiftUI

/// A card view displaying a single milestone with its tasks
struct MilestoneCardView: View {
    let milestone: GoalPlanMilestone
    let state: MilestoneState
    let index: Int
    let total: Int
    let cardWidth: CGFloat
    let onEditMilestone: () -> Void
    let onEditTask: (GoalPlanTask) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Flag header with milestone indicator
            headerSection
            
            // Due date badge
            if let dueDate = milestone.dueDate, !dueDate.isEmpty {
                dueDateBadge(dueDate: dueDate)
            }
            
            Divider()
                .padding(.horizontal, 16)
            
            // Tasks list
            tasksSection
        }
        .frame(width: cardWidth)
        .background(state.cardBackground)
        .cornerRadius(CuteClean.radiusMedium)
        .shadow(color: state.cardShadow, radius: state == .current ? 8 : 6, x: 0, y: state == .current ? 4 : 3)
        .overlay(
            // Current milestone border highlight
            RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                .stroke(state == .current ? AppColors.primary : Color.clear, lineWidth: 2)
        )
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 8) {
            // Flag icon with state-based styling
            ZStack {
                Circle()
                    .fill(state.flagColor)
                    .frame(width: 32, height: 32)
                Image(systemName: state.flagIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("里程碑 \(index + 1)/\(total)")
                        .font(AppFonts.caption)
                        .foregroundStyle(state.secondaryTextColor)
                    
                    // Status badge
                    statusBadge
                }
                Text(milestone.title)
                    .font(AppFonts.cuteLabel)
                    .foregroundStyle(state.textColor)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Edit milestone button
            Button(action: onEditMilestone) {
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.textMedium)
                    .padding(6)
                    .background(AppColors.neutralGray.opacity(0.3))
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        switch state {
        case .current:
            Text("进行中")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppColors.primary)
                .cornerRadius(4)
        case .completed:
            Text("已完成")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppColors.accentGreen)
                .cornerRadius(4)
        case .upcoming:
            EmptyView()
        }
    }
    
    // MARK: - Due Date Badge
    
    private func dueDateBadge(dueDate: String) -> some View {
        HStack {
            Text("截止: \(dueDate)")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(state.secondaryTextColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppColors.bgSageLight.opacity(0.5))
                .cornerRadius(4)
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Tasks Section
    
    private var tasksSection: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(milestone.tasks, id: \.id) { task in
                    TaskCardView(
                        task: task,
                        state: state,
                        onEdit: { onEditTask(task) }
                    )
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Task Card View

/// A card view displaying a single task within a milestone
struct TaskCardView: View {
    let task: GoalPlanTask
    let state: MilestoneState
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(state.taskDotColor)
                .frame(width: 8, height: 8)
            Text(task.title)
                .font(AppFonts.small)
                .foregroundStyle(state.textColor)
                .lineLimit(2)
            
            Spacer()
            
            // Edit task button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppColors.textMedium)
                    .padding(4)
                    .background(AppColors.neutralGray.opacity(0.3))
                    .cornerRadius(4)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(state.taskBackgroundColor)
        .cornerRadius(10)
    }
}
