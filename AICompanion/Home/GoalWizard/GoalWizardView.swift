import SwiftUI
import Combine

public struct GoalWizardView: View {
    private let userId: Int
    private let candidateDescription: String?
    private let source: String?
    private let onDismiss: () -> Void
    
    @State private var messages: [Message] = []
    @State private var draftMessage: String = ""
    @State private var isSending: Bool = false
    @State private var errorText: String?
    @State private var inputMode: InputMode = .text
    @State private var currentStage: Stage? = nil
    @State private var isFetchingPlan: Bool = false
    @State private var hasAutoConfirmedSplitting: Bool = false
    @State private var isAutoContinuingPlanGeneration: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    
    // State to track goal completion
    @State private var currentGoalId: Int?
    @State private var goalPlan: GoalPlanResponse?
    
    public init(userId: Int, candidateDescription: String? = nil, source: String? = nil, onDismiss: @escaping () -> Void) {
        self.userId = userId
        self.candidateDescription = candidateDescription
        self.source = source
        self.onDismiss = onDismiss
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
        ZStack(alignment: .top) {
            AppColors.gradientBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                contentView
            }
        }
        .padding(.bottom, keyboardHeight)
        .animation(.easeOut(duration: 0.25), value: keyboardHeight)
        .onAppear(perform: setupInitialMessage)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UIKeyboardWillShowNotification"))) { notification in
            if let frame = notification.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? CGRect {
                keyboardHeight = frame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UIKeyboardWillHideNotification"))) { _ in
            keyboardHeight = 0
        }
        .onChange(of: currentStage) { _, newStage in
            guard let newStage else { return }
            if newStage == .goalSplittingExpert {
                autoContinueAfterGoalSplittingIfNeeded()
            }
        }
        .overlay(loadingOverlay)
    }
    
    private var header: some View {
        HStack {
            Text("创建新目标")
                .font(AppFonts.large)
                .foregroundStyle(AppColors.textBlack)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.neutralGray)
                    .padding(8)
                    .background(Color.white)
                    .clipShape(Circle())
            }
        }
        .padding(24)
    }
    
    private var contentView: some View {
        VStack(spacing: 16) {
            if let currentStage {
                stageInfoView(for: currentStage)
            }
            
            messagesScrollView
            
            if let errorText {
                errorView(text: errorText)
            }
            
            inputArea
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }
    
    private func stageInfoView(for stage: Stage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(stageTitle(for: stage))
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textBlack)
            
            progressBar(progress: stageProgress(for: stage))
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
    }
    
    private let loadingIndicatorId = "loading-indicator"
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        chatBubble(for: message)
                            .id(message.id)
                    }
                    
                    if isSending {
                        HStack {
                            ChatBubbleLoadingIndicator(
                                isActive: $isSending,
                                subtitle: isAutoContinuingPlanGeneration ? "正在根据目标创建计划，请稍候" : nil
                            )
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .id(loadingIndicatorId)
                    }
                }
                .padding(.vertical, 8)
            }
            .onChange(of: messages.count) { _, _ in
                if let lastId = messages.last?.id {
                    withAnimation {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
            .onChange(of: isSending) { _, newValue in
                if newValue {
                    // Scroll to loading indicator when sending starts
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo(loadingIndicatorId, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
    
    private func errorView(text: String) -> some View {
        Text(text)
            .font(AppFonts.caption)
            .foregroundStyle(AppColors.accentRed)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private var loadingOverlay: some View {
        if isFetchingPlan || isAutoContinuingPlanGeneration {
            ZStack {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(AppColors.purple)
                    
                    Text(isAutoContinuingPlanGeneration ? "正在根据目标创建计划，请稍候" : "正在制定计划详情")
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
        .padding(.horizontal, 24)
    }
    
    private func bubbleView(text: String, isUser: Bool) -> some View {
        Text(text)
            .font(AppFonts.body)
            .foregroundStyle(AppColors.textBlack)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isUser ? AppColors.neutralGray : Color.white)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
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
        
        // If candidate description exists, use it to start the flow automatically
        if let candidate = candidateDescription, !candidate.isEmpty {
            // We add it as a user message to context, and send it
            let userMessage = Message(text: candidate, sender: .user)
            messages.append(userMessage)
            
            // Automatically send to backend
            sendMessage(candidate)
        } else {
            // Otherwise, standard greeting
            let text = "你好！我是你的目标设定助手。告诉我你想达成什么目标？"
            let message = Message(text: text, sender: .ai)
            messages.append(message)
        }
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
        
        // Don't append user message if it was already appended (e.g. initial candidate)
        if messages.last?.text != trimmed || messages.last?.sender != .user {
             let userMessage = Message(text: trimmed, sender: .user)
             messages.append(userMessage)
        }
        
        isSending = true
        errorText = nil
        
        let request = GoalOnboardingMessageRequest(userId: userId, message: trimmed)
        
        Task {
            do {
                let response = try await GoalsAPI.shared.sendOnboardingMessage(request)
                print("🟣 GoalWizard response.stage =", response.stage)
                
                let newStage = mapStage(from: response.stage)
                currentStage = newStage
                
                if let goalId = response.goalId {
                    currentGoalId = goalId
                }
                
                let replyText = response.reply.trimmingCharacters(in: .whitespacesAndNewlines)
                if !replyText.isEmpty {
                    let aiMessage = Message(text: replyText, sender: .ai)
                    messages.append(aiMessage)
                }
                
                if response.goalCompleted {
                    print("✅ Goal wizard completed, goalId =", response.goalId ?? -1)
                    // Dismiss wizard after short delay or let user read
                    // Ideally fetch plan and show success, then dismiss
                    if let goalId = currentGoalId ?? response.goalId {
                        await fetchGoalPlan(goalId: goalId)
                    }
                }
            } catch {
                errorText = "消息发送失败，请检查网络后稍后再试。"
                print("❌ Goal wizard message error:", error)
            }
            
            if !isAutoContinuingPlanGeneration {
                isSending = false
            }
        }
    }
    
    private func autoContinueAfterGoalSplittingIfNeeded() {
        guard !hasAutoConfirmedSplitting else { return }
        hasAutoConfirmedSplitting = true
        
        isSending = true
        isAutoContinuingPlanGeneration = true
        errorText = nil
        
        let request = GoalOnboardingMessageRequest(userId: userId, message: "ok")
        
        Task {
            do {
                let response = try await GoalsAPI.shared.sendOnboardingMessage(request)
                let newStage = mapStage(from: response.stage)
                currentStage = newStage
                
                if let goalId = response.goalId {
                    currentGoalId = goalId
                }
                
                if response.goalCompleted {
                    if let goalId = currentGoalId ?? response.goalId {
                        await fetchGoalPlan(goalId: goalId)
                    }
                }
            } catch {
                errorText = "生成目标计划时出了点问题，请稍后再试。"
                print("❌ Goal wizard auto-confirm error:", error)
            }
            
            isSending = false
            isAutoContinuingPlanGeneration = false
        }
    }
    
    @MainActor
    private func fetchGoalPlan(goalId: Int) async {
        guard !isFetchingPlan else { return }
        isFetchingPlan = true
        
        do {
            let plan = try await GoalsAPI.shared.fetchGoalPlan(goalId: goalId)
            goalPlan = plan
            
            // Success! Wait a moment then dismiss
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s
            onDismiss()
            
        } catch {
            errorText = "暂时无法获取目标计划，请稍后再试。"
            print("❌ Fetch goal plan error:", error)
        }
        
        isFetchingPlan = false
    }
    
    private func toggleInputMode() {
        switch inputMode {
        case .text:
            inputMode = .voice
        case .voice:
            inputMode = .text
        }
    }
}
