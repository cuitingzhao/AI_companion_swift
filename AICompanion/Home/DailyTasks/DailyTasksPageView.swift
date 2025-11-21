import SwiftUI

struct DailyTasksPageView: View {
    let loadError: String?
    let isLoading: Bool
    let tasks: [DailyTaskItemResponse]
    let actionError: String?
    let onTaskTapped: (DailyTaskItemResponse) -> Void
    let onQuickComplete: (DailyTaskItemResponse) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let error = loadError {
                Text(error)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.accentRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if isLoading {
                ProgressView()
                    .tint(AppColors.purple)
                    .padding(.top, 40)
            } else {
                DailyTasksSectionView(
                    tasks: tasks,
                    actionError: actionError,
                    onTaskTapped: onTaskTapped,
                    onQuickComplete: onQuickComplete
                )
            }
        }
    }
}
