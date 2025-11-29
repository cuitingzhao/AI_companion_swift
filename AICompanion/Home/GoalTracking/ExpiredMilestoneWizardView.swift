import SwiftUI

/// Wizard flow for handling expired milestones
struct ExpiredMilestoneWizardView: View {
    @Binding var isPresented: Bool
    let expiredMilestones: [ExpiredMilestoneInfo]
    var onComplete: (() -> Void)?
    
    // MARK: - State
    
    @State private var currentStep: WizardStep = .review
    @State private var milestoneStatuses: [Int: MilestoneStatus] = [:] // milestoneId -> status
    @State private var milestoneDueDates: [Int: Date] = [:] // milestoneId -> new due date
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showDatePicker: Bool = false
    @State private var selectedMilestoneForDate: ExpiredMilestoneInfo?
    
    enum WizardStep {
        case review      // Step 1: Review all milestones
        case success     // Step 2a: All completed
        case restart     // Step 2b: Handle unfulfilled milestones
    }
    
    enum MilestoneStatus {
        case completed   // 达成
        case notCompleted // 未达成
        case restart     // 重新开始
        case skip        // 跳过
    }
    
    // MARK: - Computed Properties
    
    private var allMilestonesReviewed: Bool {
        expiredMilestones.allSatisfy { milestone in
            milestoneStatuses[milestone.milestoneId] != nil
        }
    }
    
    private var allCompleted: Bool {
        expiredMilestones.allSatisfy { milestone in
            milestoneStatuses[milestone.milestoneId] == .completed
        }
    }
    
    private var unfulfilledMilestones: [ExpiredMilestoneInfo] {
        expiredMilestones.filter { milestone in
            let status = milestoneStatuses[milestone.milestoneId]
            return status == .notCompleted || status == .restart || status == .skip
        }
    }
    
    private var milestonesToRestart: [ExpiredMilestoneInfo] {
        expiredMilestones.filter { milestone in
            milestoneStatuses[milestone.milestoneId] == .restart
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    // Prevent dismissal by tapping background
                }
            
            // Wizard content
            VStack(spacing: 0) {
                switch currentStep {
                case .review:
                    reviewStepView
                case .success:
                    successStepView
                case .restart:
                    restartStepView
                }
            }
            .background(AppColors.gradientBackground)
            .cornerRadius(24)
            .padding(.horizontal, 20)
            .padding(.vertical, 60)
            
            // Date picker dialog
            if showDatePicker, let milestone = selectedMilestoneForDate {
                datePickerDialog(for: milestone)
            }
        }
    }
    
    // MARK: - Step 1: Review
    
    private var reviewStepView: some View {
        VStack(spacing: 0) {
            // Header
            Text("⛳️以下里程碑的截止日期已到，\n请确认该计划是否已达成？")
                .font(AppFonts.large)
                .foregroundStyle(AppColors.textBlack)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 24)
            
            // Milestone list
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(expiredMilestones, id: \.milestoneId) { milestone in
                        milestoneReviewCard(milestone)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100) // Space for floating button
            }
            
            Spacer()
            
            // Floating button
            VStack {
                Spacer()
                Button(action: handleNextStep) {
                    Text("下一步")
                        .font(AppFonts.body)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(allMilestonesReviewed ? AppColors.purple : AppColors.neutralGray)
                        .cornerRadius(12)
                }
                .disabled(!allMilestonesReviewed)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    private func milestoneReviewCard(_ milestone: ExpiredMilestoneInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Goal title
            if let goalTitle = milestone.goalTitle {
                Text(goalTitle)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textMedium)
            }
            
            // Milestone title
            Text(milestone.title)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textBlack)
            
            // Due date
            if let dueDate = milestone.dueDate {
                Text("截止日期：\(dueDate)")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.accentRed)
            }
            
            // Status buttons
            HStack {
                Spacer()
                
                Button(action: {
                    milestoneStatuses[milestone.milestoneId] = .completed
                }) {
                    Text("达成")
                        .font(AppFonts.body)
                        .foregroundStyle(milestoneStatuses[milestone.milestoneId] == .completed ? .white : AppColors.purple)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(milestoneStatuses[milestone.milestoneId] == .completed ? AppColors.purple : Color.clear)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColors.purple, lineWidth: 1)
                        )
                }
                
                Button(action: {
                    milestoneStatuses[milestone.milestoneId] = .notCompleted
                }) {
                    Text("未达成")
                        .font(AppFonts.body)
                        .foregroundStyle(milestoneStatuses[milestone.milestoneId] == .notCompleted ? .white : AppColors.neutralGray)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(milestoneStatuses[milestone.milestoneId] == .notCompleted ? AppColors.neutralGray : Color.clear)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColors.neutralGray, lineWidth: 1)
                        )
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Step 2a: Success
    
    private var successStepView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Celebration icon
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppColors.accentYellow)
            
            Text("太棒了！")
                .font(AppFonts.title)
                .foregroundStyle(AppColors.textBlack)
            
            Text("你离达成目标又近了一步，加油呀！")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textMedium)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button(action: handleComplete) {
                Text("返回")
                    .font(AppFonts.body)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.purple)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - Step 2b: Restart
    
    private var restartStepView: some View {
        VStack(spacing: 0) {
            // Header
            Text("🧐你是否想继续这些里程碑计划？")
                .font(AppFonts.large)
                .foregroundStyle(AppColors.textBlack)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 24)
            
            // Unfulfilled milestone list
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(unfulfilledMilestones, id: \.milestoneId) { milestone in
                        milestoneRestartCard(milestone)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100) // Space for floating button
            }
            
            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.accentRed)
                    .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Floating button
            VStack {
                Spacer()
                Button(action: handleSave) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        Text("保存")
                            .font(AppFonts.body)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .background(AppColors.purple)
                .cornerRadius(12)
                .disabled(isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    private func milestoneRestartCard(_ milestone: ExpiredMilestoneInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Goal title
            if let goalTitle = milestone.goalTitle {
                Text(goalTitle)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textMedium)
            }
            
            // Milestone title
            Text(milestone.title)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textBlack)
            
            // New due date if set
            if let newDate = milestoneDueDates[milestone.milestoneId] {
                let formatter = DateFormatter()
                let _ = formatter.dateFormat = "yyyy-MM-dd"
                Text("新截止日期：\(formatter.string(from: newDate))")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.purple)
            }
            
            // Action buttons
            HStack {
                Spacer()
                
                Button(action: {
                    selectedMilestoneForDate = milestone
                    showDatePicker = true
                    milestoneStatuses[milestone.milestoneId] = .restart
                }) {
                    Text("延续计划")
                        .font(AppFonts.body)
                        .foregroundStyle(milestoneStatuses[milestone.milestoneId] == .restart ? .white : AppColors.purple)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(milestoneStatuses[milestone.milestoneId] == .restart ? AppColors.purple : Color.clear)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColors.purple, lineWidth: 1)
                        )
                }
                
                Button(action: {
                    milestoneStatuses[milestone.milestoneId] = .skip
                    milestoneDueDates.removeValue(forKey: milestone.milestoneId)
                }) {
                    Text("跳过该里程碑")
                        .font(AppFonts.body)
                        .foregroundStyle(milestoneStatuses[milestone.milestoneId] == .skip ? .white : AppColors.neutralGray)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(milestoneStatuses[milestone.milestoneId] == .skip ? AppColors.neutralGray : Color.clear)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColors.neutralGray, lineWidth: 1)
                        )
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Date Picker Dialog
    
    private func datePickerDialog(for milestone: ExpiredMilestoneInfo) -> some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    showDatePicker = false
                }
            
            VStack(spacing: 20) {
                Text("选择新的截止日期")
                    .font(AppFonts.large)
                    .foregroundStyle(AppColors.textBlack)
                
                DatePicker(
                    "",
                    selection: Binding(
                        get: { milestoneDueDates[milestone.milestoneId] ?? Date().addingTimeInterval(7 * 24 * 60 * 60) },
                        set: { milestoneDueDates[milestone.milestoneId] = $0 }
                    ),
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "zh_CN"))
                
                Button(action: {
                    // Ensure a date is set
                    if milestoneDueDates[milestone.milestoneId] == nil {
                        milestoneDueDates[milestone.milestoneId] = Date().addingTimeInterval(7 * 24 * 60 * 60)
                    }
                    showDatePicker = false
                }) {
                    Text("确定")
                        .font(AppFonts.body)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColors.purple)
                        .cornerRadius(8)
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Actions
    
    private func handleNextStep() {
        if allCompleted {
            // All milestones completed - call API and go to success
            Task {
                await markAllCompleted()
                currentStep = .success
            }
        } else {
            // Some not completed - go to restart step
            currentStep = .restart
        }
    }
    
    private func markAllCompleted() async {
        isLoading = true
        
        for milestone in expiredMilestones {
            if milestoneStatuses[milestone.milestoneId] == .completed {
                let request = MilestoneActionRequest(action: "complete")
                do {
                    _ = try await GoalsAPI.shared.performMilestoneAction(
                        milestoneId: milestone.milestoneId,
                        request: request
                    )
                } catch {
                    print("❌ Failed to mark milestone \(milestone.milestoneId) as completed:", error)
                }
            }
        }
        
        isLoading = false
    }
    
    private func handleSave() {
        Task {
            await saveRestartMilestones()
        }
    }
    
    private func saveRestartMilestones() async {
        isLoading = true
        errorMessage = nil
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        // First, mark completed milestones
        for milestone in expiredMilestones {
            if milestoneStatuses[milestone.milestoneId] == .completed {
                let request = MilestoneActionRequest(action: "complete")
                do {
                    _ = try await GoalsAPI.shared.performMilestoneAction(
                        milestoneId: milestone.milestoneId,
                        request: request
                    )
                } catch {
                    print("❌ Failed to mark milestone \(milestone.milestoneId) as completed:", error)
                }
            }
        }
        
        // Then, reopen milestones with new due dates
        for milestone in unfulfilledMilestones {
            if milestoneStatuses[milestone.milestoneId] == .restart,
               let newDate = milestoneDueDates[milestone.milestoneId] {
                let dateString = formatter.string(from: newDate)
                let request = MilestoneActionRequest(action: "reopen", newDueDate: dateString)
                do {
                    _ = try await GoalsAPI.shared.performMilestoneAction(
                        milestoneId: milestone.milestoneId,
                        request: request
                    )
                } catch {
                    print("❌ Failed to reopen milestone \(milestone.milestoneId):", error)
                    errorMessage = "保存失败，请稍后再试"
                }
            }
            // Skipped milestones stay expired - backend handles not prompting again
        }
        
        isLoading = false
        
        if errorMessage == nil {
            // Dismiss and show toast
            isPresented = false
            onComplete?()
        }
    }
    
    private func handleComplete() {
        isPresented = false
        onComplete?()
    }
}
