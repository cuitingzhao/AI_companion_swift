import SwiftUI

// MARK: - Task Execution Overlay

/// Overlay for displaying task execution card and loading state
struct TaskExecutionOverlay: View {
    let selectedTask: DailyTaskItemResponse?
    let isUpdating: Bool
    @Binding var showCompleteConfirmation: Bool
    @Binding var showDeleteConfirmation: Bool
    @Binding var taskForConfirmation: DailyTaskItemResponse?
    let onDismiss: () -> Void
    let onAction: (ExecutionAction, DailyTaskItemResponse) -> Void
    
    var body: some View {
        ZStack {
            // Loading overlay
            if isUpdating {
                loadingOverlay
            }
            
            // Task detail card overlay
            if let task = selectedTask {
                taskDetailOverlay(task: task)
            }
            
            // Confirmation dialogs
            confirmationDialogs
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .tint(AppColors.purple)

                Text("正在更新待办事项状态，请稍候")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textBlack)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color.white)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 6)
        }
    }
    
    // MARK: - Task Detail Overlay
    
    private func taskDetailOverlay(task: DailyTaskItemResponse) -> some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            GeometryReader { geometry in
                VStack {
                    Spacer()
                    TaskExecutionCardView(
                        task: task,
                        width: geometry.size.width * 0.82,
                        onAction: { action in
                            onAction(action, task)
                            onDismiss()
                        },
                        onRequestComplete: {
                            taskForConfirmation = task
                            showCompleteConfirmation = true
                            onDismiss()
                        },
                        onRequestDelete: {
                            taskForConfirmation = task
                            showDeleteConfirmation = true
                            onDismiss()
                        }
                    )
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Confirmation Dialogs
    
    private var confirmationDialogs: some View {
        ZStack {
            AppDialog(
                isPresented: $showCompleteConfirmation,
                message: "确定要完成「\(taskForConfirmation?.title ?? "")」吗？",
                primaryTitle: "确认完成",
                primaryAction: {
                    if let task = taskForConfirmation {
                        onAction(.complete, task)
                    }
                    showCompleteConfirmation = false
                    taskForConfirmation = nil
                },
                secondaryTitle: "取消",
                secondaryAction: {
                    showCompleteConfirmation = false
                    taskForConfirmation = nil
                },
                title: "完成任务"
            )
            
            AppDialog(
                isPresented: $showDeleteConfirmation,
                message: "确定要删除「\(taskForConfirmation?.title ?? "")」吗？删除后无法恢复。",
                primaryTitle: "确认删除",
                primaryAction: {
                    if let task = taskForConfirmation {
                        onAction(.cancel, task)
                    }
                    showDeleteConfirmation = false
                    taskForConfirmation = nil
                },
                secondaryTitle: "取消",
                secondaryAction: {
                    showDeleteConfirmation = false
                    taskForConfirmation = nil
                },
                title: "删除任务"
            )
        }
    }
}

// MARK: - Execution Action Enum

/// Actions that can be performed on a task execution
enum ExecutionAction {
    case complete
    case cancel
    case postpone
}
