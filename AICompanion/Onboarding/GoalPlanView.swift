import SwiftUI

public struct GoalPlanView: View {
    @ObservedObject private var state: OnboardingState
    @State private var isIntroDialogPresented: Bool = true

    public init(state: OnboardingState) {
        self.state = state
    }

    private var plan: GoalPlanResponse? {
        state.goalPlan
    }

    public var body: some View {
        OnboardingScaffold(topSpacing: 60, containerColor: .clear, header: { EmptyView() }) {
            VStack(spacing: 24) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let plan {
                            goalHeader(plan: plan)
                            timelineCard(plan: plan)
                        } else {
                            Text("目标计划尚未生成")
                                .font(AppFonts.body)
                                .foregroundStyle(AppColors.neutralGray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(spacing: 12) {
                    PrimaryButton(
                        action: {
                            print("✅ User chose to start tasks today")
                            state.currentStep = .taskForToday
                        },
                        style: .init(variant: .filled, verticalPadding: 12)
                    ) {
                        Text("立即开始")
                            .foregroundStyle(.white)
                    }

                    PrimaryButton(
                        action: {
                            print("ℹ️ User chose to start tasks tomorrow")
                        },
                        style: .init(variant: .outlined, verticalPadding: 12)
                    ) {
                        Text("明天再提醒我")
                            .foregroundStyle(AppColors.purple)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .overlay(
            AppDialog(
                isPresented: $isIntroDialogPresented,
                message: "这是为你制定的计划。随着我对你的了解加深，这个计划也会不断调整。我每天会从计划中挑选部分事项，你可以在每日待办页面查看。",
                primaryTitle: "知道了",
                primaryAction: {},
                title: "目标计划说明"
            )
        )
    }

    private func goalHeader(plan: GoalPlanResponse) -> some View {
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

    private func timelineCard(plan: GoalPlanResponse) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(plan.milestones, id: \.id) { milestone in
                milestoneTimelineRow(milestone: milestone)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    private func milestoneTimelineRow(milestone: GoalPlanMilestone) -> some View {
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
                    taskCard(title: task.title)
                }
            }
        }
    }

    private func taskCard(title: String) -> some View {
        Text(title)
            .font(AppFonts.small)
            .foregroundStyle(AppColors.textBlack)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.purple.opacity(0.06))
            .cornerRadius(12)
    }
}

#Preview {
    let state = OnboardingState()
    return GoalPlanView(state: state)
}
