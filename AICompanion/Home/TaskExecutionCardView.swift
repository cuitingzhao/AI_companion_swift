import SwiftUI

struct TaskExecutionCardView: View {
    let task: DailyTaskItemResponse
    let width: CGFloat
    let onAction: (HomeDailyTasksView.ExecutionAction) -> Void
    // Callbacks for full-screen confirmation dialogs
    var onRequestComplete: (() -> Void)?
    var onRequestDelete: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            Text(task.goalTitle ?? "今日待办")
                .font(AppFonts.small)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppColors.lavender)

            VStack(spacing: 16) {
                Text(task.title)
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textBlack)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let minutes = task.estimatedMinutes {
                    Text("预计用时：\(minutes) 分钟")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.neutralGray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 32) {
                    actionButton(color: .red, systemImage: "minus", label: "删除") {
                        if let onRequestDelete {
                            onRequestDelete()
                        } else {
                            onAction(.cancel)
                        }
                    }

                    actionButton(color: .green, systemImage: "checkmark", label: "完成") {
                        if let onRequestComplete {
                            onRequestComplete()
                        } else {
                            onAction(.complete)
                        }
                    }

                    let canPostpone = !(task.frequency == "daily" || task.frequency == "weekdays")

                    actionButton(color: .yellow, systemImage: "clock", label: "推迟", disabled: !canPostpone) {
                        if canPostpone {
                            onAction(.postpone)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
        .frame(width: width, height: 320, alignment: .top)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)
    }

    private func actionButton(color: Color, systemImage: String, label: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        VStack(spacing: 6) {
            Button(action: action) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 40, height: 40)
                    .background(disabled ? AppColors.neutralGray.opacity(0.4) : color)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(disabled)

            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textBlack)
        }
    }
}
