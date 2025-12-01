// 这个文件不需要了，之后删除

import SwiftUI

public struct TaskForTodayView: View {
    private let userId: Int?
    private let onStart: () -> Void

    @State private var isLoading: Bool = true
    @State private var plan: DailyTaskPlanResponse?
    @State private var errorText: String?

    public init(userId: Int?, onStart: @escaping () -> Void = {}) {
        self.userId = userId
        self.onStart = onStart
    }

    public var body: some View {
        ZStack(alignment: .top) {
            AppColors.gradientBackground
                .ignoresSafeArea()

            Image("star_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.6)

            VStack(spacing: 24) {
                Spacer(minLength: 60)

                Text("今日待执行的小行动")
                    .font(AppFonts.large)
                    .foregroundStyle(AppColors.textBlack)

                if isLoading {
                    loadingView
                } else if let plan {
                    contentView(for: plan)
                } else if let errorText {
                    errorView(text: errorText)
                } else {
                    emptyView
                }

                PrimaryButton(
                    action: onStart,
                    style: .init(variant: .filled, verticalPadding: 14)
                ) {
                    Text("开始")
                        .foregroundStyle(.white)
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear(perform: loadPlanIfNeeded)
    }

    @ViewBuilder
    private func contentView(for plan: DailyTaskPlanResponse) -> some View {
        let groups = goalGroups(from: plan)

        if groups.isEmpty {
            emptyView
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(groups) { group in
                        GoalTaskListCard(group: group)
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxHeight: 420)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(AppColors.purple)

            Text("正在为你获取今日待办事项，请稍候…")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textBlack)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private func errorView(text: String) -> some View {
        VStack(spacing: 12) {
            Text(text)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.accentRed)

            Button(action: {
                isLoading = true
                errorText = nil
                loadPlanIfNeeded()
            }) {
                Text("重试")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.purple)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private var emptyView: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.78

            HStack {
                Spacer()

                VStack(spacing: 0) {
                    Text("今日待办")
                        .font(AppFonts.small)
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(AppColors.lavender)

                    VStack {
                        Spacer()

                        Text("还没有待办事项，\n歇一歇吧。")
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
                .frame(width: cardWidth, height: 360)
                .background(Color.white)
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)

                Spacer()
            }
        }
    }

    private func loadPlanIfNeeded() {
        guard isLoading else { return }

        guard let userId else {
            errorText = "系统暂时无法获取你的账户信息，今日待办事项暂时无法加载，请稍后再试。"
            isLoading = false
            return
        }

        Task {
            do {
                let response = try await ExecutionsAPI.shared.fetchDailyPlan(userId: userId)
                plan = response
                errorText = nil
            } catch {
                errorText = "暂时无法获取今日的待办事项，请稍后再试。"
                print("❌ fetchDailyPlan error:", error)
            }

            isLoading = false
        }
    }

    private func goalGroups(from plan: DailyTaskPlanResponse) -> [GoalTaskGroup] {
        let grouped = Dictionary(grouping: plan.items) { item in
            item.goalId
        }

        return grouped.map { key, items in
            let title = items.first?.goalTitle ?? "未命名目标"
            return GoalTaskGroup(id: key, goalTitle: title, items: items)
        }
        .sorted { $0.goalTitle < $1.goalTitle }
    }
}

private struct GoalTaskGroup: Identifiable {
    let id: Int
    let goalTitle: String
    let items: [DailyTaskItemResponse]
}

private struct GoalTaskListCard: View {
    let group: GoalTaskGroup

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.78

            VStack(spacing: 0) {
                Text(group.goalTitle)
                    .font(AppFonts.small)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppColors.lavender)

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 12) {
                        ForEach(group.items, id: \.executionId) { item in
                            TaskDetailCardView(title: item.title, minutes: item.estimatedMinutes)
                        }
                    }
                    .padding(16)
                }
            }
            .frame(width: cardWidth, height: 360)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)
        }
    }
}

private struct TaskDetailCardView: View {
    let title: String
    let minutes: Int?

    @State private var isGlowing: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(AppFonts.small)
                .foregroundStyle(AppColors.textBlack)
                .lineLimit(3)
                .truncationMode(.tail)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 8)

            if let minutes {
                ZStack {
                    Circle()
                        .stroke(AppColors.purple, lineWidth: 2)
                        .frame(width: 44, height: 44)

                    Text("\(minutes)")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.purple)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.purple.opacity(0.04))
        .cornerRadius(18)
        .shadow(color: AppColors.purple.opacity(isGlowing ? 0.45 : 0.18), radius: isGlowing ? 18 : 8, x: 0, y: 0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                isGlowing = true
            }
        }
    }
}

#Preview {
    TaskForTodayView(userId: 1)
}

