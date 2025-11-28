import SwiftUI

struct DailyTasksSectionView: View {
    let tasks: [DailyTaskItemResponse]
    let actionError: String?
    let hasActiveGoals: Bool
    let isAssigningTasks: Bool
    let allTasksCompleted: Bool
    let onTaskTapped: (DailyTaskItemResponse) -> Void
    let onQuickComplete: (DailyTaskItemResponse) -> Void
    let onAssignTasks: () -> Void
    // Callback to show full-screen confirmation dialog
    var onRequestComplete: ((DailyTaskItemResponse) -> Void)?

    var body: some View {
        if tasks.isEmpty {
            emptyTasksCard
        } else {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.purple)

                    Text("今天还有\(tasks.count)个小任务待完成")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.purple)
                }

                VStack(spacing: 12) {
                    ForEach(Array(tasks.enumerated()), id: \.element.executionId) { _, item in
                        let iconColor = priorityColor(for: item.priority)

                        HStack(spacing: 12) {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(iconColor.opacity(0.85))
                                    .frame(width: 6, height: 6)

                                Circle()
                                    .fill(iconColor.opacity(0.85))
                                    .frame(width: 6, height: 6)

                                Circle()
                                    .fill(iconColor.opacity(0.85))
                                    .frame(width: 6, height: 6)
                            }
                            .frame(width: 12)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(AppFonts.small)
                                    .foregroundStyle(AppColors.textBlack)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

                                if let minutes = item.estimatedMinutes {
                                    Text("预计用时：\(minutes) 分钟")
                                        .font(AppFonts.caption)
                                        .foregroundStyle(AppColors.neutralGray)
                                }
                            }

                            Spacer(minLength: 8)

                            // Finch 3D Checkmark Button
                            Button(action: {
                                if let onRequestComplete {
                                    onRequestComplete(item)
                                } else {
                                    onQuickComplete(item)
                                }
                            }) {
                                ZStack {
                                    // Depth layer
                                    Circle()
                                        .fill(AppColors.accentGreen.opacity(0.6))
                                        .frame(width: 38, height: 38)
                                        .offset(y: 4)
                                    
                                    // Main button face
                                    Circle()
                                        .fill(AppColors.accentGreen)
                                        .frame(width: 38, height: 38)
                                    
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(Color.white)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onTaskTapped(item)
                        }
                    }
                }

                if let actionError {
                    Text(actionError)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.accentRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var emptyTasksCard: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.82

            HStack {
                Spacer()

                VStack(spacing: 0) {
                    // Finch-inspired: Sage green header
                    Text("今日待办")
                        .font(AppFonts.cuteLabel)
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppColors.primary)

                    VStack(spacing: 16) {
                        Spacer()

                        if allTasksCompleted {
                            // All tasks for today have been completed
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(AppColors.accentGreen)
                            
                            Text("太棒了！今日任务已全部完成 🎉")
                                .font(AppFonts.body)
                                .foregroundStyle(AppColors.textDark)
                                .multilineTextAlignment(.center)
                            
                            Text("好好休息，明天继续加油！")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textLight)
                                .multilineTextAlignment(.center)
                        } else if hasActiveGoals {
                            // Has goals but no tasks assigned yet
                            Text("今天还没有安排任务哦～")
                                .font(AppFonts.body)
                                .foregroundStyle(AppColors.textDark)
                                .multilineTextAlignment(.center)
                            
                            Text("点击下方按钮，让我帮你安排今日任务")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textLight)
                                .multilineTextAlignment(.center)
                            
                            // Finch 3D Button for assigning tasks
                            Button(action: onAssignTasks) {
                                HStack(spacing: 8) {
                                    if isAssigningTasks {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "calendar.badge.plus")
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                    }
                                    Text("安排今日任务")
                                        .font(AppFonts.cuteButton)
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                                            .fill(AppColors.primaryDepth)
                                            .offset(y: 4)
                                        RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                                            .fill(AppColors.primary)
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isAssigningTasks)
                        } else {
                            // No goals at all
                            Text("今天没有待办事项，\n可以休息一下啦 ☺️")
                                .font(AppFonts.body)
                                .foregroundStyle(AppColors.textDark)
                                .multilineTextAlignment(.center)
                            
                            Text("创建目标后，我会帮你安排每日任务")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textLight)
                                .multilineTextAlignment(.center)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(20)
                }
                .frame(width: cardWidth, height: 300)
                .background(AppColors.cardWhite)
                .cornerRadius(CuteClean.radiusMedium)
                .shadow(color: AppColors.shadowColor, radius: 8, x: 0, y: 4)

                Spacer()
            }
        }
    }

    private func priorityColor(for priority: String) -> Color {
        switch priority {
        case "high":
            return AppColors.accentRed
        case "medium":
            return AppColors.textBlack
        default:
            return AppColors.neutralGray
        }
    }
}
