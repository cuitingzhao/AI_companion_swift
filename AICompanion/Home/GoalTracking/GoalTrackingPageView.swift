import SwiftUI

struct GoalTrackingPageView: View {
    let plans: [GoalPlanResponse]
    let isLoading: Bool
    let errorText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GoalTrackingSectionView(
                plans: plans,
                isLoading: isLoading,
                errorText: errorText
            )
        }
    }
}
