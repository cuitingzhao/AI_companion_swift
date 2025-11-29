import SwiftUI

/// A horizontal scrollable timeline view displaying milestones
struct MilestoneTimelineView: View {
    let plan: GoalPlanResponse
    let currentMilestoneIds: Set<Int>
    let onEditMilestone: (GoalPlanMilestone) -> Void
    let onEditTask: (GoalPlanTask) -> Void
    
    private let mascotHeight: CGFloat = 80
    private let cardHeight: CGFloat = 380
    
    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.85
            let cardSpacing: CGFloat = 16
            
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(0..<plan.milestones.count, id: \.self) { index in
                            let milestone = plan.milestones[index]
                            let state = calculateMilestoneState(
                                for: milestone,
                                at: index,
                                in: plan.milestones,
                                currentMilestoneIds: currentMilestoneIds
                            )
                            
                            HStack(spacing: 0) {
                                // Milestone card with mascot container above
                                VStack(spacing: 0) {
                                    // Transparent container for bouncing mascot gif
                                    mascotContainer(isCurrent: state == .current)
                                        .frame(height: mascotHeight)
                                    
                                    // Milestone card
                                    MilestoneCardView(
                                        milestone: milestone,
                                        state: state,
                                        index: index,
                                        total: plan.milestones.count,
                                        cardWidth: cardWidth,
                                        onEditMilestone: { onEditMilestone(milestone) },
                                        onEditTask: { task in onEditTask(task) }
                                    )
                                }
                                .id(index)
                                
                                // Connecting line to next milestone (except for last)
                                if index < plan.milestones.count - 1 {
                                    let nextState = calculateMilestoneState(
                                        for: plan.milestones[index + 1],
                                        at: index + 1,
                                        in: plan.milestones,
                                        currentMilestoneIds: currentMilestoneIds
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
                    if let currentIndex = findCurrentMilestoneIndex(
                        in: plan.milestones,
                        currentMilestoneIds: currentMilestoneIds
                    ) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                scrollProxy.scrollTo(currentIndex, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .frame(height: mascotHeight + cardHeight)
    }
    
    // MARK: - Mascot Container
    
    private func mascotContainer(isCurrent: Bool) -> some View {
        ZStack {
            if isCurrent {
                GIFImage(name: "bouncing")
                    .frame(width: 140, height: 80)
            }
        }
        .frame(width: 140, height: mascotHeight)
    }
    
    // MARK: - Connecting Line
    
    private func connectingLine(fromState: MilestoneState, toState: MilestoneState) -> some View {
        let lineColor = connectingLineColor(fromState: fromState, toState: toState)
        
        return VStack {
            Spacer()
                .frame(height: 24) // Align with flag icon center
            Rectangle()
                .fill(lineColor)
                .frame(height: 2)
            Spacer()
        }
    }
}
