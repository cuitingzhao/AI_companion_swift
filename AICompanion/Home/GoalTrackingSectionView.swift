import SwiftUI

struct GoalTrackingSectionView: View {
    let plans: [GoalPlanResponse]
    let isLoading: Bool
    let errorText: String?

    var body: some View {
        if isLoading {
            VStack(spacing: 12) {
                ProgressView()
                    .tint(AppColors.purple)

                Text("正在为你加载目标计划，请稍候…")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textBlack)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 40)
        } else if let errorText {
            Text(errorText)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.accentRed)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 40)
        } else if !plans.isEmpty {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(plans, id: \.goalId) { plan in
                    VStack(alignment: .leading, spacing: 16) {
                        goalTrackingHeader(plan: plan)
                        goalTrackingTimelineCard(plan: plan)
                    }
                    .padding(.horizontal, 4)
                }
            }
        } else {
            Text("目标计划尚未生成")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.neutralGray)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func goalTrackingHeader(plan: GoalPlanResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text("目标")
                    .font(AppFonts.large)
                    .foregroundStyle(AppColors.textBlack)

                Spacer()

                if let due = plan.dueDate, !due.isEmpty {
                    Text("截止日期：\(due)")
                        .font(AppFonts.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColors.textBlack)
                        .cornerRadius(14)
                }
            }

            Text(plan.title)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textBlack)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func goalTrackingTimelineCard(plan: GoalPlanResponse) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(plan.milestones, id: \.id) { milestone in
                goalTrackingMilestoneRow(milestone: milestone)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    private func goalTrackingMilestoneRow(milestone: GoalPlanMilestone) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.accentRed)

                Spacer(minLength: 0)
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(AppColors.neutralGray.opacity(0.4))
                    .frame(width: 2)
                    .padding(.top, 18)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(milestone.title)
                    .font(AppFonts.small)
                    .foregroundStyle(AppColors.textBlack)

                ForEach(milestone.tasks, id: \.id) { task in
                    goalTrackingTaskCard(title: task.title)
                }
            }
        }
    }

    private func goalTrackingTaskCard(title: String) -> some View {
        Text(title)
            .font(AppFonts.small)
            .foregroundStyle(AppColors.textBlack)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.purple.opacity(0.06))
            .cornerRadius(12)
    }
}
