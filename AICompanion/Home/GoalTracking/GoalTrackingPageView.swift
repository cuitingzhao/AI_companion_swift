import SwiftUI

struct GoalTrackingPageView: View {
    let plans: [GoalPlanResponse]
    let isLoading: Bool
    let errorText: String?
    let onAddGoal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Add Goal Button
            Button(action: onAddGoal) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("创建新目标")
                        .font(AppFonts.small)
                }
                .foregroundStyle(AppColors.purple)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppColors.purple.opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            GoalTrackingSectionView(
                plans: plans,
                isLoading: isLoading,
                errorText: errorText
            )
        }
    }
}

#Preview {
    GoalTrackingPageView(
        plans: [],
        isLoading: false,
        errorText: nil,
        onAddGoal: {}
    )
    .padding()
}
