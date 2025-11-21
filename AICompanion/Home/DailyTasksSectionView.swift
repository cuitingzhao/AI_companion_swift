import SwiftUI

struct DailyTasksSectionView: View {
    let tasks: [DailyTaskItemResponse]
    let actionError: String?
    let onTaskTapped: (DailyTaskItemResponse) -> Void
    let onQuickComplete: (DailyTaskItemResponse) -> Void

    var body: some View {
        if tasks.isEmpty {
            emptyTasksCard
        } else {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.white)

                    Text("今天还有\(tasks.count)个小任务待完成")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.white)
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

                            Button(action: {
                                onQuickComplete(item)
                            }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Color.white)
                                    .frame(width: 38, height: 38)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                AppColors.accentGreen,
                                                AppColors.accentGreen.opacity(0.85)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .clipShape(Circle())
                                    .shadow(color: AppColors.accentGreen.opacity(0.4), radius: 8, x: 0, y: 4)
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
        let cardWidth = UIScreen.main.bounds.width * 0.82

        return HStack {
            Spacer()

            VStack(spacing: 0) {
                Text("今日待办")
                    .font(AppFonts.small)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppColors.purple)

                VStack {
                    Spacer()

                    Text("今天没有待办事项，\n可以休息一下啦。")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textBlack)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(16)
            }
            .frame(width: cardWidth, height: 280)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)

            Spacer()
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
