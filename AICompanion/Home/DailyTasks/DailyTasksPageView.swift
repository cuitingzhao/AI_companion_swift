import SwiftUI

struct DailyTasksPageView: View {
    let loadError: String?
    let isLoading: Bool
    let tasks: [DailyTaskItemResponse]
    let actionError: String?
    let hasActiveGoals: Bool
    let isAssigningTasks: Bool
    let allTasksCompleted: Bool
    let weeklyCompletion: [DailyCompletionItem]
    let onTaskTapped: (DailyTaskItemResponse) -> Void
    let onQuickComplete: (DailyTaskItemResponse) -> Void
    let onAssignTasks: () -> Void
    // Callback for full-screen confirmation dialog
    var onRequestComplete: ((DailyTaskItemResponse) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Weekly calendar widget
            WeeklyCalendarWidget(weeklyCompletion: weeklyCompletion)
            
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
                    hasActiveGoals: hasActiveGoals,
                    isAssigningTasks: isAssigningTasks,
                    allTasksCompleted: allTasksCompleted,
                    onTaskTapped: onTaskTapped,
                    onQuickComplete: onQuickComplete,
                    onAssignTasks: onAssignTasks,
                    onRequestComplete: onRequestComplete
                )
            }
        }
    }
}

// MARK: - Weekly Calendar Widget

struct WeeklyCalendarWidget: View {
    let weeklyCompletion: [DailyCompletionItem]
    
    private let weekdays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                let dayInfo = dayInfoForIndex(index)
                VStack(spacing: 6) {
                    // Day label
                    Text(weekdays[index])
                        .font(AppFonts.caption)
                        .foregroundStyle(dayInfo.isToday ? AppColors.primary : AppColors.textLight)
                    
                    // Date circle
                    ZStack {
                        Circle()
                            .fill(dayInfo.backgroundColor)
                            .frame(width: 36, height: 36)
                        
                        Text("\(dayInfo.dayNumber)")
                            .font(AppFonts.small)
                            .foregroundStyle(dayInfo.textColor)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        // .background(AppColors.cardWhite)
        .cornerRadius(CuteClean.radiusMedium)
        .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
    }
    
    private struct DayInfo {
        let dayNumber: Int
        let isToday: Bool
        let backgroundColor: Color
        let textColor: Color
    }
    
    private func dayInfoForIndex(_ index: Int) -> DayInfo {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        // weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        let daysFromMonday = (weekday + 5) % 7
        
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today),
              let targetDate = calendar.date(byAdding: .day, value: index, to: monday) else {
            return DayInfo(dayNumber: 0, isToday: false, backgroundColor: AppColors.cardWhite, textColor: AppColors.textLight)
        }
        
        let dayNumber = calendar.component(.day, from: targetDate)
        let isToday = calendar.isDateInToday(targetDate)
        
        // Find completion data for this date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: targetDate)
        
        let completion = weeklyCompletion.first { $0.date == dateString }
        
        // Determine background color based on completion
        let backgroundColor: Color
        let textColor: Color
        
        if isToday {
            // Today - always use primary color
            backgroundColor = AppColors.primary
            textColor = .white
        } else if targetDate > today {
            // Future date - white/no color
            backgroundColor = AppColors.cardWhite
            textColor = AppColors.textLight
        } else if let completion = completion {
            if completion.completionRate >= 1.0 {
                // All tasks completed - green
                backgroundColor = AppColors.accentGreen
                textColor = .white
            } else {
                // Has tasks but not all completed - red
                backgroundColor = AppColors.accentRed
                textColor = .white
            }
        } else {
            // No tasks for this day - white
            backgroundColor = AppColors.cardWhite
            textColor = AppColors.textLight
        }
        
        return DayInfo(
            dayNumber: dayNumber,
            isToday: isToday,
            backgroundColor: backgroundColor,
            textColor: textColor
        )
    }
}
