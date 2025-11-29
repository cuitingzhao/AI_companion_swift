import SwiftUI

// MARK: - Goal Edit Dialog

struct GoalEditDialog: View {
    @Binding var isPresented: Bool
    let goal: GoalPlanResponse
    let onSave: (GoalUpdateRequest) async -> Void
    var onSuccess: ((String) -> Void)?
    
    @State private var title: String = ""
    @State private var dueDate: Date = Date()
    @State private var hasDueDate: Bool = false
    @State private var status: String = "active"
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @State private var showStatusConfirmation: Bool = false
    @State private var pendingStatus: String?
    
    private let statusOptions = [
        ("active", "进行中"),
        ("completed", "已完成"),
        ("abandoned", "已放弃")
    ]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    var body: some View {
        ZStack {
            DialogContainer(isPresented: $isPresented, allowDismissOnTap: !isSaving) {
                VStack(spacing: 20) {
                    DialogHeader(title: "编辑目标", onClose: { isPresented = false }, isDisabled: isSaving)
                    
                    LabeledTextField(label: "目标名称", placeholder: "输入目标名称", text: $title)
                    
                    DateTogglePicker(label: "截止日期", hasDate: $hasDueDate, date: $dueDate)
                    
                    OptionPicker(
                        label: "状态",
                        options: statusOptions,
                        selectedValue: $status,
                        onSelectionChange: { newStatus in
                            if newStatus != status && newStatus != goal.status {
                                pendingStatus = newStatus
                                showStatusConfirmation = true
                            } else {
                                status = newStatus
                            }
                        }
                    )
                    
                    DialogErrorMessage(message: errorMessage)
                    
                    DialogButtonRow(
                        isSaving: isSaving,
                        isSaveDisabled: title.isEmpty,
                        onCancel: { isPresented = false },
                        onSave: saveGoal
                    )
                }
            }
            
            ConfirmationDialogOverlay(
                isPresented: $showStatusConfirmation,
                title: "确认更改状态",
                message: "目标状态的更改会影响其关联的所有里程碑和任务，确认更改吗？",
                onConfirm: {
                    if let newStatus = pendingStatus {
                        status = newStatus
                    }
                    pendingStatus = nil
                }
            )
        }
        .onAppear {
            title = goal.title
            status = goal.status ?? "active"
            if let dueDateStr = goal.dueDate, let date = dateFormatter.date(from: dueDateStr) {
                dueDate = date
                hasDueDate = true
            }
        }
    }
    
    private func saveGoal() {
        isSaving = true
        errorMessage = nil
        
        let request = GoalUpdateRequest(
            title: title != goal.title ? title : nil,
            status: status != goal.status ? status : nil,
            dueDate: hasDueDate ? dateFormatter.string(from: dueDate) : nil
        )
        
        let successCallback = onSuccess
        Task {
            await onSave(request)
            await MainActor.run {
                isSaving = false
                isPresented = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    successCallback?("目标已更新")
                }
            }
        }
    }
}

// MARK: - Milestone Edit Dialog

struct MilestoneEditDialog: View {
    @Binding var isPresented: Bool
    let milestone: GoalPlanMilestone
    let onSave: (MilestoneUpdateRequest) async -> Void
    var onSuccess: ((String) -> Void)?
    
    @State private var title: String = ""
    @State private var desc: String = ""
    @State private var dueDate: Date = Date()
    @State private var hasDueDate: Bool = false
    @State private var priority: String = "medium"
    @State private var status: String = "active"
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @State private var showStatusConfirmation: Bool = false
    @State private var pendingStatus: String?
    
    private let priorities = [("high", "高"), ("medium", "中"), ("low", "低")]
    
    // Note: "expired" is set by system when goal is abandoned, not manually by user
    private let statusOptions = [
        ("active", "进行中"),
        ("completed", "已完成")
    ]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isSaving {
                        isPresented = false
                    }
                }
            
            ScrollView {
                VStack(spacing: 20) {
                    DialogHeader(title: "编辑里程碑", onClose: { isPresented = false }, isDisabled: isSaving)
                    
                    LabeledTextField(label: "里程碑名称", placeholder: "输入里程碑名称", text: $title)
                    
                    LabeledTextField(
                        label: "描述（可选）",
                        placeholder: "输入描述",
                        text: $desc,
                        lineLimit: 3...5
                    )
                    
                    OptionPicker(label: "优先级", options: priorities, selectedValue: $priority)
                    
                    DateTogglePicker(label: "截止日期", hasDate: $hasDueDate, date: $dueDate)
                    
                    OptionPicker(
                        label: "状态",
                        options: statusOptions,
                        selectedValue: $status,
                        onSelectionChange: { newStatus in
                            if newStatus != status && newStatus != milestone.status {
                                pendingStatus = newStatus
                                showStatusConfirmation = true
                            } else {
                                status = newStatus
                            }
                        }
                    )
                    
                    DialogErrorMessage(message: errorMessage)
                    
                    DialogButtonRow(
                        isSaving: isSaving,
                        isSaveDisabled: title.isEmpty,
                        onCancel: { isPresented = false },
                        onSave: saveMilestone
                    )
                }
                .padding(24)
                .background(AppColors.neoWhite)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
                .padding(.horizontal, 32)
                .padding(.vertical, 60)
            }
            
            ConfirmationDialogOverlay(
                isPresented: $showStatusConfirmation,
                title: "确认更改状态",
                message: "里程碑状态的更改会影响其关联的所有任务，确认更改吗？",
                onConfirm: {
                    if let newStatus = pendingStatus {
                        status = newStatus
                    }
                    pendingStatus = nil
                }
            )
        }
        .onAppear {
            title = milestone.title
            desc = milestone.desc ?? ""
            priority = milestone.priority
            status = milestone.status ?? "active"
            if let dueDateStr = milestone.dueDate, let date = dateFormatter.date(from: dueDateStr) {
                dueDate = date
                hasDueDate = true
            }
        }
    }
    
    private func saveMilestone() {
        isSaving = true
        errorMessage = nil
        
        let request = MilestoneUpdateRequest(
            title: title != milestone.title ? title : nil,
            desc: desc != (milestone.desc ?? "") ? desc : nil,
            dueDate: hasDueDate ? dateFormatter.string(from: dueDate) : nil,
            priority: priority != milestone.priority ? priority : nil,
            status: status != milestone.status ? status : nil
        )
        
        let successCallback = onSuccess
        Task {
            await onSave(request)
            await MainActor.run {
                isSaving = false
                isPresented = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    successCallback?("里程碑已更新")
                }
            }
        }
    }
}

// MARK: - Task Edit Dialog

struct TaskEditDialog: View {
    @Binding var isPresented: Bool
    let task: GoalPlanTask
    let onSave: (TaskUpdateRequest) async -> Void
    var onSuccess: ((String) -> Void)?
    
    @State private var title: String = ""
    @State private var priority: String = "medium"
    @State private var frequency: String = "once"
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    
    private let priorities = [("high", "高"), ("medium", "中"), ("low", "低")]
    private let frequencies = [
        ("once", "一次"),
        ("daily", "每天"),
        ("weekdays", "工作日"),
        ("weekly", "每周"),
        ("monthly", "每月")
    ]
    
    var body: some View {
        DialogContainer(isPresented: $isPresented, allowDismissOnTap: !isSaving) {
            VStack(spacing: 20) {
                DialogHeader(title: "编辑任务", onClose: { isPresented = false }, isDisabled: isSaving)
                
                LabeledTextField(label: "任务名称", placeholder: "输入任务名称", text: $title)
                
                OptionPicker(label: "优先级", options: priorities, selectedValue: $priority)
                
                OptionPicker(label: "频率", options: frequencies, selectedValue: $frequency)
                
                DialogErrorMessage(message: errorMessage)
                
                DialogButtonRow(
                    isSaving: isSaving,
                    isSaveDisabled: title.isEmpty,
                    onCancel: { isPresented = false },
                    onSave: saveTask
                )
            }
        }
        .onAppear {
            title = task.title
            priority = task.priority ?? "medium"
            frequency = task.frequency
        }
    }
    
    private func saveTask() {
        isSaving = true
        errorMessage = nil
        
        let request = TaskUpdateRequest(
            title: title != task.title ? title : nil,
            priority: priority != (task.priority ?? "medium") ? priority : nil,
            frequency: frequency != task.frequency ? frequency : nil
        )
        
        let successCallback = onSuccess
        Task {
            await onSave(request)
            await MainActor.run {
                isSaving = false
                isPresented = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    successCallback?("任务已更新")
                }
            }
        }
    }
}
