import SwiftUI
import Combine

public struct GoalOnboardingChatView: View {
    @ObservedObject private var state: OnboardingState

    @State private var messages: [Message] = []
    @State private var draftMessage: String = ""
    @State private var isSending: Bool = false
    @State private var errorText: String?
    @State private var keyboardHeight: CGFloat = 0
    @State private var inputMode: InputMode = .text
    @State private var currentStage: Stage? = nil
    @State private var isFetchingPlan: Bool = false
    @State private var loadingDotsStep: Int = 0
    @State private var hasAutoConfirmedSplitting: Bool = false
    @State private var isAutoContinuingPlanGeneration: Bool = false

    public init(state: OnboardingState) {
        self.state = state
    }

    private struct Message: Identifiable, Equatable {
        enum Sender {
            case user
            case ai
        }

        let id = UUID()
        let text: String
        let sender: Sender
    }

    private enum InputMode: Hashable {
        case text
        case voice
    }

    private enum Stage {
        case operatorStage
        case goalSettingExpert
        case goalSplittingExpert
        case done
        case error
    }

    public var body: some View {
        OnboardingScaffold(topSpacing: 60, header: { EmptyView() }) {
            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    Button(action: handleSkip) {
                        Text("跳过")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.purple)
                    }
                    .buttonStyle(.plain)
                }

                if let currentStage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(stageTitle(for: currentStage))
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textBlack)

                        progressBar(progress: stageProgress(for: currentStage))
                            .frame(maxWidth: .infinity)
                    }
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                chatBubble(for: message)
                                    .id(message.id)
                            }

                            if isSending {
                                HStack {
                                    bubbleLoadingIndicator()
                                    Spacer()
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onChange(of: messages.count) { _ in
                        if let lastId = messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }

                if let errorText {
                    Text(errorText)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.accentRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                inputArea
            }
        }
        .padding(.bottom, keyboardHeight)
        .animation(.easeOut(duration: 0.25), value: keyboardHeight)
        .onAppear(perform: setupInitialMessage)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UIKeyboardWillShowNotification"))) { notification in
            if let frameValue = notification.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? NSValue {
                keyboardHeight = frameValue.cgRectValue.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UIKeyboardWillHideNotification"))) { _ in
            keyboardHeight = 0
        }
        .onChange(of: currentStage) { newStage in
            guard let newStage else { return }
            if newStage == .goalSplittingExpert {
                autoContinueAfterGoalSplittingIfNeeded()
            }
        }
        .overlay(
            Group {
                if isFetchingPlan {
                    ZStack {
                        Color.black.opacity(0.25)
                            .ignoresSafeArea()

                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(AppColors.purple)

                            Text("正在制定计划详情")
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
            }
        )
    }

    private func progressBar(progress: Double) -> some View {
        let clamped = max(0, min(1, progress))

        return ZStack(alignment: .leading) {
            Capsule()
                .fill(AppColors.purple.opacity(0.15))

            Capsule()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            AppColors.purple.opacity(0.4),
                            AppColors.purple
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .scaleEffect(x: clamped, y: 1, anchor: .leading)
        }
        .frame(height: 6)
    }

    private func stageTitle(for stage: Stage) -> String {
        switch stage {
        case .operatorStage:
            return "1/3 目标澄清中"
        case .goalSettingExpert:
            return "2/3 目标设定中"
        case .goalSplittingExpert:
            return "3/3 正在为你拆解目标"
        case .done:
            return "目标计划已生成"
        case .error:
            return "目标设定出错，请稍后重试"
        }
    }

    private func bubbleLoadingIndicator() -> some View {
        let dotsCount = (loadingDotsStep % 3) + 3 // cycles through 3,4,5 dots
        let dots = String(repeating: ".", count: dotsCount)

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(AppColors.purple)

                Text(dots)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textBlack)
            }

            if isAutoContinuingPlanGeneration {
                Text("正在根据目标创建计划，请稍候")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textBlack)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(18)
        .onAppear {
            loadingDotsStep = 0
        }
        .onReceive(Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()) { _ in
            guard isSending else { return }
            loadingDotsStep += 1
        }
    }

    private func stageProgress(for stage: Stage) -> Double {
        switch stage {
        case .operatorStage:
            return 1.0 / 3.0
        case .goalSettingExpert:
            return 2.0 / 3.0
        case .goalSplittingExpert, .done:
            return 1.0
        case .error:
            return 0.0
        }
    }

    private func mapStage(from backendValue: String) -> Stage? {
        switch backendValue {
        case "operator":
            return .operatorStage
        case "goal_setting_expert":
            return .goalSettingExpert
        case "goal_splitting_expert":
            return .goalSplittingExpert
        case "done":
            return .done
        case "error":
            return .error
        default:
            return nil
        }
    }

    private func chatBubble(for message: Message) -> some View {
        HStack {
            if message.sender == .ai {
                bubbleView(text: message.text, isUser: false)
                Spacer()
            } else {
                Spacer()
                bubbleView(text: message.text, isUser: true)
            }
        }
    }

    private func bubbleView(text: String, isUser: Bool) -> some View {
        Text(text)
            .font(AppFonts.body)
            .foregroundStyle(AppColors.textBlack)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isUser ? AppColors.neutralGray : Color.white)
            .cornerRadius(18)
    }

    @ViewBuilder
    private var inputArea: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                if inputMode == .text {
                    AppTextField(
                        "请输入内容",
                        text: $draftMessage,
                        submitLabel: SubmitLabel.send,
                        onSubmit: {
                            sendCurrentMessage()
                        }
                    )
                } else {
                    VoiceInputButton(
                        text: $draftMessage,
                        style: .longPress,
                        onComplete: { text in
                            sendMessage(text)
                        }
                    )
                }

                Button(action: toggleInputMode) {
                    Image(systemName: inputMode == .text ? "mic.fill" : "keyboard")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.purple)
                }
            }
        }
        .disabled(isSending || isFetchingPlan)
    }

    private func setupInitialMessage() {
        guard messages.isEmpty else { return }
        let nickname = state.nickname
        let text = "\(nickname)，太棒了！现在我们一起来设定一个你真正想完成的目标吧。你可以先告诉我，你最近最想达成的一个目标是什么？"
        let message = Message(text: text, sender: .ai)
        messages.append(message)
    }

    private func sendCurrentMessage() {
        guard !isSending, !isFetchingPlan else { return }
        let content = draftMessage
        draftMessage = ""
        sendMessage(content)
    }

    private func sendMessage(_ content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let userId = state.submitUserId else {
            errorText = "缺少用户信息，暂时无法发送。"
            return
        }

        let userMessage = Message(text: trimmed, sender: .user)
        messages.append(userMessage)
        isSending = true
        errorText = nil

        let request = GoalOnboardingMessageRequest(userId: userId, message: trimmed)

        Task {
            do {
                let response = try await GoalsAPI.shared.sendOnboardingMessage(request)
                print("🟣 GoalOnboarding message response.stage =", response.stage,
                      "goalCompleted =", response.goalCompleted,
                      "goalId =", response.goalId ?? -1)

                let previousStage = currentStage
                let newStage = mapStage(from: response.stage)
                currentStage = newStage

                print("🟣 GoalOnboarding mapped stage from", response.stage,
                      "to", String(describing: newStage),
                      "previous =", String(describing: previousStage))

                if let goalId = response.goalId {
                    state.currentGoalId = goalId
                }

                let replyText = response.reply.trimmingCharacters(in: .whitespacesAndNewlines)
                if !replyText.isEmpty {
                    let aiMessage = Message(text: replyText, sender: .ai)
                    messages.append(aiMessage)
                }

                if response.goalCompleted {
                    print("✅ Goal onboarding completed, goalId =", response.goalId ?? -1, "stage =", response.stage)

                    if let goalId = state.currentGoalId ?? response.goalId {
                        await fetchGoalPlan(goalId: goalId)
                    } else {
                        print("❌ No goalId available for fetching plan")
                    }
                }
            } catch {
                errorText = "发送失败，请稍后重试。"
                print("❌ Goal onboarding message error:", error)
            }
            if !isAutoContinuingPlanGeneration {
                isSending = false
            }
        }
    }

    private func autoContinueAfterGoalSplittingIfNeeded() {
        guard !hasAutoConfirmedSplitting else { return }
        hasAutoConfirmedSplitting = true

        guard let userId = state.submitUserId else {
            print("❌ No user ID available for goal splitting confirmation")
            return
        }

        isSending = true
        isAutoContinuingPlanGeneration = true
        errorText = nil

        print("🟢 GoalOnboarding auto-continue fired for goal_splitting_expert, userId =", userId)

        let request = GoalOnboardingMessageRequest(userId: userId, message: "ok")

        Task {
            do {
                let response = try await GoalsAPI.shared.sendOnboardingMessage(request)
                print("🟢 GoalOnboarding auto response.stage =", response.stage,
                      "goalCompleted =", response.goalCompleted,
                      "goalId =", response.goalId ?? -1)

                let previousStage = currentStage
                let newStage = mapStage(from: response.stage)
                currentStage = newStage

                print("🟢 GoalOnboarding auto mapped stage from", response.stage,
                      "to", String(describing: newStage),
                      "previous =", String(describing: previousStage))

                if let goalId = response.goalId {
                    state.currentGoalId = goalId
                }

                if response.goalCompleted {
                    print("✅ Goal onboarding completed after auto-confirm, goalId =", response.goalId ?? -1, "stage =", response.stage)

                    if let goalId = state.currentGoalId ?? response.goalId {
                        await fetchGoalPlan(goalId: goalId)
                    } else {
                        print("❌ No goalId available for fetching plan after auto-confirm")
                    }
                }
            } catch {
                errorText = "生成目标计划时出错，请稍后重试。"
                print("❌ Goal onboarding auto-confirm error:", error)
            }

            isSending = false
            isAutoContinuingPlanGeneration = false
        }
    }

    private func toggleInputMode() {
        switch inputMode {
        case .text:
            inputMode = .voice
        case .voice:
            inputMode = .text
        }
    }

    private func handleSkip() {
        guard let userId = state.submitUserId else {
            errorText = "缺少用户信息，暂时无法跳过。"
            return
        }

        let request = GoalOnboardingSkipRequest(userId: userId)

        Task {
            do {
                let response = try await GoalsAPI.shared.skipOnboarding(request)
                print("✅ Goal onboarding skipped:", response.message)
            } catch {
                errorText = "跳过失败，请稍后重试。"
                print("❌ Goal onboarding skip error:", error)
            }
        }
    }

    @MainActor
    private func fetchGoalPlan(goalId: Int) async {
        guard !isFetchingPlan else { return }
        isFetchingPlan = true

        do {
            let plan = try await GoalsAPI.shared.fetchGoalPlan(goalId: goalId)

            let hasMilestones = !plan.milestones.isEmpty
            let hasTasks = plan.milestones.contains { !$0.tasks.isEmpty }

            if hasMilestones && hasTasks {
                state.goalPlan = plan
                state.currentStep = .goalPlan
            } else {
                errorText = "目前生成的目标计划还不够完整，我们会继续为你优化，请稍后再试。"
                print("ℹ️ Goal plan is empty or has no tasks, staying in chat.")
            }
        } catch {
            errorText = "获取目标计划失败，请稍后重试。"
            print("❌ Fetch goal plan error:", error)
        }

        isFetchingPlan = false
    }
}

#Preview {
    let state = OnboardingState()
    state.nickname = "测试用户"
    return GoalOnboardingChatView(state: state)
}
