import SwiftUI

struct GoalTrackingSectionView: View {
    let plan: GoalPlanResponse?
    let currentMilestoneIds: Set<Int>
    let isLoading: Bool
    let errorText: String?

    var body: some View {
        if isLoading {
            VStack(spacing: 12) {
                ProgressView()
                    .tint(AppColors.purple)

                Text("正在为你加载目标计划，请稍候…")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textBlack)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 40)
        } else if let errorText {
            Text(errorText)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.accentRed)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 40)
        } else if let plan {
            VStack(alignment: .leading, spacing: 16) {
                goalTrackingHeader(plan: plan)
                horizontalMilestoneTimeline(plan: plan)
            }
            .padding(.horizontal, 4)
        } else {
            Text("目标计划尚未生成")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.neutralGray)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Milestone State Helpers
    
    private enum MilestoneState {
        case completed
        case current
        case upcoming
    }
    
    private func milestoneState(for milestone: GoalPlanMilestone, at index: Int, in milestones: [GoalPlanMilestone]) -> MilestoneState {
        // If milestone is marked completed
        if milestone.status == "completed" {
            return .completed
        }
        
        // If this milestone has tasks assigned today, it's current
        if currentMilestoneIds.contains(milestone.id) {
            return .current
        }
        
        // If milestone is in_progress status
        if milestone.status == "in_progress" {
            return .current
        }
        
        // Check if any previous milestone is still not completed
        // If so, this one is upcoming
        let previousMilestones = milestones.prefix(index)
        let allPreviousCompleted = previousMilestones.allSatisfy { $0.status == "completed" }
        
        if !allPreviousCompleted {
            return .upcoming
        }
        
        // If all previous are completed but this one isn't current, it's upcoming
        return .upcoming
    }
    
    /// Find the index of the first current milestone for auto-scroll
    private func currentMilestoneIndex(in milestones: [GoalPlanMilestone]) -> Int? {
        for (index, milestone) in milestones.enumerated() {
            let state = milestoneState(for: milestone, at: index, in: milestones)
            if state == .current {
                return index
            }
        }
        // If no current found, find first non-completed
        for (index, milestone) in milestones.enumerated() {
            if milestone.status != "completed" {
                return index
            }
        }
        return nil
    }

    private func goalTrackingHeader(plan: GoalPlanResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text("目标")
                    .font(AppFonts.large)
                    .foregroundStyle(AppColors.textBlack)

                Spacer()                
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
    
    // MARK: - Horizontal Milestone Timeline
    
    private let mascotHeight: CGFloat = 80
    private let cardHeight: CGFloat = 380
    
    private func horizontalMilestoneTimeline(plan: GoalPlanResponse) -> some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.85
            let cardSpacing: CGFloat = 16
            
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(0..<plan.milestones.count, id: \.self) { index in
                            let milestone = plan.milestones[index]
                            let state = milestoneState(for: milestone, at: index, in: plan.milestones)
                            
                            HStack(spacing: 0) {
                                // Milestone card with mascot container above
                                VStack(spacing: 0) {
                                    // Transparent container for bouncing mascot gif
                                    mascotContainer(isCurrent: state == .current)
                                        .frame(height: mascotHeight)
                                    
                                    // Milestone card with flag
                                    milestoneCard(
                                        milestone: milestone,
                                        state: state,
                                        index: index,
                                        total: plan.milestones.count,
                                        cardWidth: cardWidth
                                    )
                                }
                                .id(index)
                                
                                // Connecting line to next milestone (except for last)
                                if index < plan.milestones.count - 1 {
                                    let nextState = milestoneState(
                                        for: plan.milestones[index + 1],
                                        at: index + 1,
                                        in: plan.milestones
                                    )
                                    connectingLine(fromState: state, toState: nextState)
                                        .frame(width: cardSpacing)
                                        .padding(.top, mascotHeight) // Align with card, not mascot
                                }
                            }
                        }
                    }
                    .padding(.horizontal, (geometry.size.width - cardWidth) / 2)
                }
                .onAppear {
                    // Auto-scroll to current milestone
                    if let currentIndex = currentMilestoneIndex(in: plan.milestones) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                scrollProxy.scrollTo(currentIndex, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .frame(height: mascotHeight + cardHeight) // Mascot + card height
    }
    
    // MARK: - Mascot Container
    
    private func mascotContainer(isCurrent: Bool) -> some View {
        ZStack {
            // Only show mascot on current milestone
            if isCurrent {
                GIFImage(name: "bouncing")
                    .frame(width: 140, height: 80)
            }
        }
        .frame(width: 140, height: mascotHeight)
    }
    
    private func milestoneCard(milestone: GoalPlanMilestone, state: MilestoneState, index: Int, total: Int, cardWidth: CGFloat) -> some View {
        let isCompleted = state == .completed
        let isCurrent = state == .current
        let isUpcoming = state == .upcoming
        
        return VStack(alignment: .leading, spacing: 0) {
            // Flag header with milestone indicator
            HStack(spacing: 8) {
                // Flag icon with state-based styling
                ZStack {
                    Circle()
                        .fill(flagColor(for: state))
                        .frame(width: 32, height: 32)
                    Image(systemName: flagIcon(for: state))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("里程碑 \(index + 1)/\(total)")
                            .font(AppFonts.caption)
                            .foregroundStyle(isUpcoming ? AppColors.textLight : AppColors.textMedium)
                        
                        // Status badge
                        if isCurrent {
                            Text("进行中")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColors.primary)
                                .cornerRadius(4)
                        } else if isCompleted {
                            Text("已完成")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColors.accentGreen)
                                .cornerRadius(4)
                        }
                                               
                    }
                    Text(milestone.title)
                        .font(AppFonts.cuteLabel)
                        .foregroundStyle(isUpcoming ? AppColors.textLight : AppColors.textBlack)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Due date badge
            if let dueDate = milestone.dueDate, !dueDate.isEmpty {
                HStack {
                    Text("截止: \(dueDate)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(isUpcoming ? AppColors.textLight : AppColors.textMedium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.bgSageLight.opacity(0.5))
                        .cornerRadius(4)
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            
            Divider()
                .padding(.horizontal, 16)
            
            // Tasks list
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(milestone.tasks, id: \.id) { task in
                        taskCard(title: task.title, state: state)
                    }
                }
                .padding(16)
            }
        }
        .frame(width: cardWidth)
        .background(cardBackground(for: state))
        .cornerRadius(CuteClean.radiusMedium)
        .shadow(color: cardShadow(for: state), radius: isCurrent ? 8 : 6, x: 0, y: isCurrent ? 4 : 3)
        .overlay(
            // Current milestone border highlight
            RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                .stroke(isCurrent ? AppColors.primary : Color.clear, lineWidth: 2)
        )
    }
    
    // MARK: - State-based Styling Helpers
    
    private func flagColor(for state: MilestoneState) -> Color {
        switch state {
        case .completed:
            return AppColors.accentGreen
        case .current:
            return AppColors.primary
        case .upcoming:
            return AppColors.neutralGray
        }
    }
    
    private func flagIcon(for state: MilestoneState) -> String {
        switch state {
        case .completed:
            return "checkmark"
        case .current:
            return "flag.fill"
        case .upcoming:
            return "flag"
        }
    }
    
    private func cardBackground(for state: MilestoneState) -> Color {
        switch state {
        case .completed:
            return Color.white.opacity(0.9)
        case .current:
            return Color.white
        case .upcoming:
            return Color.white.opacity(0.7)
        }
    }
    
    private func cardShadow(for state: MilestoneState) -> Color {
        switch state {
        case .completed:
            return AppColors.shadowColor.opacity(0.5)
        case .current:
            return AppColors.primary.opacity(0.2)
        case .upcoming:
            return AppColors.shadowColor.opacity(0.3)
        }
    }
    
    private func connectingLine(fromState: MilestoneState, toState: MilestoneState) -> some View {
        let lineColor: Color = {
            if fromState == .completed && toState == .completed {
                return AppColors.accentGreen.opacity(0.6)
            } else if fromState == .completed || fromState == .current {
                return AppColors.primary.opacity(0.4)
            } else {
                return AppColors.neutralGray.opacity(0.3)
            }
        }()
        
        return VStack {
            Spacer()
                .frame(height: 24) // Align with flag icon center
            Rectangle()
                .fill(lineColor)
                .frame(height: 2)
            Spacer()
        }
    }
    
    private func taskCard(title: String, state: MilestoneState) -> some View {
        let textColor: Color = state == .upcoming ? AppColors.textLight : AppColors.textBlack
        let dotColor: Color = {
            switch state {
            case .completed:
                return AppColors.accentGreen.opacity(0.5)
            case .current:
                return AppColors.primary.opacity(0.5)
            case .upcoming:
                return AppColors.neutralGray.opacity(0.3)
            }
        }()
        let bgColor: Color = {
            switch state {
            case .completed:
                return AppColors.accentGreen.opacity(0.06)
            case .current:
                return AppColors.purple.opacity(0.08)
            case .upcoming:
                return AppColors.neutralGray.opacity(0.06)
            }
        }()
        
        return HStack(spacing: 10) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
            Text(title)
                .font(AppFonts.small)
                .foregroundStyle(textColor)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bgColor)
        .cornerRadius(10)
    }
}
