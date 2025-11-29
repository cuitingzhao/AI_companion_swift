import SwiftUI

// MARK: - Milestone State

/// Represents the visual state of a milestone in the timeline
enum MilestoneState {
    case completed
    case current
    case upcoming
}

// MARK: - State Calculation

/// Determines the state of a milestone based on its status and position
/// Milestone statuses from backend:
/// - "pending": Not started yet (default state)
/// - "active": Has tasks assigned, currently being worked on
/// - "completed": Finished
/// - "expired": Past due date without completion
func calculateMilestoneState(
    for milestone: GoalPlanMilestone,
    at index: Int,
    in milestones: [GoalPlanMilestone],
    currentMilestoneIds: Set<Int>
) -> MilestoneState {
    // If milestone is marked completed
    if milestone.status == "completed" {
        return .completed
    }
    
    // If milestone is active (has tasks assigned), it's current
    if milestone.status == "active" {
        return .current
    }
    
    // If this milestone has tasks assigned today, it's current
    if currentMilestoneIds.contains(milestone.id) {
        return .current
    }
    
    // Pending or expired milestones are upcoming
    return .upcoming
}

/// Find the index of the first current milestone for auto-scroll
func findCurrentMilestoneIndex(
    in milestones: [GoalPlanMilestone],
    currentMilestoneIds: Set<Int>
) -> Int? {
    for (index, milestone) in milestones.enumerated() {
        let state = calculateMilestoneState(
            for: milestone,
            at: index,
            in: milestones,
            currentMilestoneIds: currentMilestoneIds
        )
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

// MARK: - Styling Helpers

extension MilestoneState {
    /// Color for the flag icon circle
    var flagColor: Color {
        switch self {
        case .completed:
            return AppColors.accentGreen
        case .current:
            return AppColors.primary
        case .upcoming:
            return AppColors.neutralGray
        }
    }
    
    /// SF Symbol name for the flag icon
    var flagIcon: String {
        switch self {
        case .completed:
            return "checkmark"
        case .current:
            return "flag.fill"
        case .upcoming:
            return "flag"
        }
    }
    
    /// Background color for the milestone card
    var cardBackground: Color {
        switch self {
        case .completed:
            return Color.white.opacity(0.9)
        case .current:
            return Color.white
        case .upcoming:
            return Color.white.opacity(0.7)
        }
    }
    
    /// Shadow color for the milestone card
    var cardShadow: Color {
        switch self {
        case .completed:
            return AppColors.shadowColor.opacity(0.5)
        case .current:
            return AppColors.primary.opacity(0.2)
        case .upcoming:
            return AppColors.shadowColor.opacity(0.3)
        }
    }
    
    /// Text color for milestone content
    var textColor: Color {
        switch self {
        case .completed, .current:
            return AppColors.textBlack
        case .upcoming:
            return AppColors.textLight
        }
    }
    
    /// Secondary text color
    var secondaryTextColor: Color {
        switch self {
        case .completed, .current:
            return AppColors.textMedium
        case .upcoming:
            return AppColors.textLight
        }
    }
    
    /// Dot color for task items
    var taskDotColor: Color {
        switch self {
        case .completed:
            return AppColors.accentGreen.opacity(0.5)
        case .current:
            return AppColors.primary.opacity(0.5)
        case .upcoming:
            return AppColors.neutralGray.opacity(0.3)
        }
    }
    
    /// Background color for task items
    var taskBackgroundColor: Color {
        switch self {
        case .completed:
            return AppColors.accentGreen.opacity(0.06)
        case .current:
            return AppColors.purple.opacity(0.08)
        case .upcoming:
            return AppColors.neutralGray.opacity(0.06)
        }
    }
}

// MARK: - Connecting Line Helper

/// Returns the color for the connecting line between milestones
func connectingLineColor(fromState: MilestoneState, toState: MilestoneState) -> Color {
    if fromState == .completed && toState == .completed {
        return AppColors.accentGreen.opacity(0.6)
    } else if fromState == .completed || fromState == .current {
        return AppColors.primary.opacity(0.4)
    } else {
        return AppColors.neutralGray.opacity(0.3)
    }
}
