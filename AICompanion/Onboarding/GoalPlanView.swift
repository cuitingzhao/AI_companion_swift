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
                            Text("暂时没有可展示的目标计划")
                                .font(AppFonts.body)
                                .foregroundStyle(AppColors.neutralGray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                PrimaryButton(
                    action: {
                        print("✅ Goal plan confirmed")
                    },
                    style: .init(variant: .filled, verticalPadding: 12)
                ) {
                    Text("确定")
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .overlay(
            AppDialog(
                isPresented: $isIntroDialogPresented,
                message: "这是根据我们刚才的讨论为你制定的计划。请知晓这个计划会随着我们的谈话增多，我对你的了解增多而产生变化。我每天都会把计划里的部分任务插入到你的日程表里，你可以在任务主页查看。",
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
        let lineHeight = CGFloat(max(1, milestone.tasks.count)) * 52

        return HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.accentRed)

                Rectangle()
                    .fill(AppColors.neutralGray.opacity(0.4))
                    .frame(width: 2, height: lineHeight)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(milestone.title)
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textBlack)

                ForEach(milestone.tasks, id: \.id) { task in
                    taskCard(title: task.title)
                }
            }
        }
    }

    private func taskCard(title: String) -> some View {
        Text(title)
            .font(AppFonts.body)
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
