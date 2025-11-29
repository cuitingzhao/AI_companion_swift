import SwiftUI
import Combine

/// ViewModel for GoalTrackingSectionView handling optimistic UI updates and API calls
@MainActor
class GoalTrackingViewModel: ObservableObject {
    // MARK: - Published State
    
    @Published var localPlan: GoalPlanResponse?
    @Published var showGoalEditDialog: Bool = false
    @Published var showMilestoneEditDialog: Bool = false
    @Published var showTaskEditDialog: Bool = false
    @Published var selectedMilestone: GoalPlanMilestone?
    @Published var selectedTask: GoalPlanTask?
    @Published var toastMessage: String?
    @Published var showToast: Bool = false
    
    // MARK: - Callbacks
    
    var onGoalUpdated: (() -> Void)?
    
    // MARK: - Computed Properties
    
    /// Returns local plan if available, otherwise returns the passed plan
    func displayPlan(from plan: GoalPlanResponse?) -> GoalPlanResponse? {
        localPlan ?? plan
    }
    
    // MARK: - Optimistic UI Updates
    
    func applyGoalUpdate(request: GoalUpdateRequest, currentPlan: GoalPlanResponse?) {
        guard let currentPlan = currentPlan else { return }
        
        let updatedPlan = GoalPlanResponse(
            goalId: currentPlan.goalId,
            title: request.title ?? currentPlan.title,
            desc: currentPlan.desc,
            dueDate: request.dueDate ?? currentPlan.dueDate,
            dailyMinutes: currentPlan.dailyMinutes,
            motivation: currentPlan.motivation,
            constraints: currentPlan.constraints,
            progress: currentPlan.progress,
            status: request.status ?? currentPlan.status,
            milestones: currentPlan.milestones
        )
        
        localPlan = updatedPlan
    }
    
    func applyMilestoneUpdate(milestoneId: Int, request: MilestoneUpdateRequest, currentPlan: GoalPlanResponse?) {
        guard let currentPlan = currentPlan else { return }
        
        let updatedMilestones = currentPlan.milestones.map { milestone -> GoalPlanMilestone in
            if milestone.id == milestoneId {
                return GoalPlanMilestone(
                    id: milestone.id,
                    title: request.title ?? milestone.title,
                    desc: request.desc ?? milestone.desc,
                    startDate: milestone.startDate,
                    dueDate: request.dueDate ?? milestone.dueDate,
                    priority: request.priority ?? milestone.priority,
                    status: request.status ?? milestone.status,
                    tasks: milestone.tasks
                )
            }
            return milestone
        }
        
        let updatedPlan = GoalPlanResponse(
            goalId: currentPlan.goalId,
            title: currentPlan.title,
            desc: currentPlan.desc,
            dueDate: currentPlan.dueDate,
            dailyMinutes: currentPlan.dailyMinutes,
            motivation: currentPlan.motivation,
            constraints: currentPlan.constraints,
            progress: currentPlan.progress,
            status: currentPlan.status,
            milestones: updatedMilestones
        )
        
        localPlan = updatedPlan
        
        // Update selected milestone for dialog
        if let updated = updatedMilestones.first(where: { $0.id == milestoneId }) {
            selectedMilestone = updated
        }
    }
    
    func applyTaskUpdate(taskId: Int, request: TaskUpdateRequest, currentPlan: GoalPlanResponse?) {
        guard let currentPlan = currentPlan else { return }
        
        let updatedMilestones = currentPlan.milestones.map { milestone -> GoalPlanMilestone in
            let updatedTasks = milestone.tasks.map { task -> GoalPlanTask in
                if task.id == taskId {
                    return GoalPlanTask(
                        id: task.id,
                        title: request.title ?? task.title,
                        desc: task.desc,
                        dueAt: task.dueAt,
                        estimatedMinutes: task.estimatedMinutes,
                        frequency: request.frequency ?? task.frequency,
                        status: request.status ?? task.status,
                        priority: request.priority ?? task.priority
                    )
                }
                return task
            }
            
            return GoalPlanMilestone(
                id: milestone.id,
                title: milestone.title,
                desc: milestone.desc,
                startDate: milestone.startDate,
                dueDate: milestone.dueDate,
                priority: milestone.priority,
                status: milestone.status,
                tasks: updatedTasks
            )
        }
        
        let updatedPlan = GoalPlanResponse(
            goalId: currentPlan.goalId,
            title: currentPlan.title,
            desc: currentPlan.desc,
            dueDate: currentPlan.dueDate,
            dailyMinutes: currentPlan.dailyMinutes,
            motivation: currentPlan.motivation,
            constraints: currentPlan.constraints,
            progress: currentPlan.progress,
            status: currentPlan.status,
            milestones: updatedMilestones
        )
        
        localPlan = updatedPlan
        
        // Update selected task for dialog
        for milestone in updatedMilestones {
            if let updated = milestone.tasks.first(where: { $0.id == taskId }) {
                selectedTask = updated
                break
            }
        }
    }
    
    // MARK: - API Calls
    
    func updateGoalAPI(goalId: Int, request: GoalUpdateRequest) async {
        do {
            _ = try await GoalsAPI.shared.updateGoal(goalId: goalId, request: request)
            onGoalUpdated?()
        } catch {
            print("❌ Failed to update goal:", error)
            // Revert optimistic update on failure
            localPlan = nil
        }
    }
    
    func updateMilestoneAPI(milestoneId: Int, request: MilestoneUpdateRequest) async {
        do {
            _ = try await GoalsAPI.shared.updateMilestone(milestoneId: milestoneId, request: request)
            onGoalUpdated?()
        } catch {
            print("❌ Failed to update milestone:", error)
            // Revert optimistic update on failure
            localPlan = nil
        }
    }
    
    func updateTaskAPI(taskId: Int, request: TaskUpdateRequest) async {
        do {
            _ = try await GoalsAPI.shared.updateTask(taskId: taskId, request: request)
            onGoalUpdated?()
        } catch {
            print("❌ Failed to update task:", error)
            // Revert optimistic update on failure
            localPlan = nil
        }
    }
    
    // MARK: - Toast
    
    func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            withAnimation {
                self?.showToast = false
            }
        }
    }
    
    // MARK: - State Reset
    
    func resetLocalPlan() {
        localPlan = nil
    }
}
