import SwiftUI

public struct KYCChatView: View {
    @ObservedObject private var state: OnboardingState

    @State private var messages: [Message] = []
    @State private var draftMessage: String = ""
    @State private var isSending: Bool = false
    @State private var errorText: String?
    @State private var inputMode: InputMode = .text
    @State private var keyboardHeight: CGFloat = 0

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

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                chatBubble(for: message)
                                    .id(message.id)
                            }

                            if isSending {
                                HStack {
                                    ChatBubbleLoadingIndicator(isActive: $isSending)
                                    Spacer()
                                }
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
                    .onChange(of: isSending) { _, sending in
                        guard sending, let lastId = messages.last?.id else { return }
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
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
        .onReceive(NotificationCenter.default.publisher(for: .keyboardWillShow)) { notification in
            if let frameValue = notification.userInfo?[KeyboardNotificationKeys.frameEnd] as? NSValue {
                keyboardHeight = frameValue.cgRectValue.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .keyboardWillHide)) { _ in
            keyboardHeight = 0
        }
    }

    private enum KeyboardNotificationKeys {
        static let frameEnd = "UIKeyboardFrameEndUserInfoKey"
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
    }

    private func setupInitialMessage() {
        guard messages.isEmpty else { return }
        let nickname = state.nickname
        let text = "嗨，\(nickname)，能否告诉我，你现在所在的城市是？"
        let message = Message(text: text, sender: .ai)
        messages.append(message)

        guard let userId = state.submitUserId else { return }

        Task { @MainActor in
            let hasUserMessageAtStart = messages.contains { $0.sender == .user }
            guard !hasUserMessageAtStart else { return }

            let result = await LocationService.shared.fetchCurrentCity()

            let hasUserMessageNow = messages.contains { $0.sender == .user }
            guard !hasUserMessageNow else { return }

            switch result {
            case .success(let location):
                let updateRequest = LocationUpdateRequest(
                    userId: userId,
                    city: location.city,
                    latitude: location.latitude,
                    longitude: location.longitude
                )

                do {
                    _ = try await ProfileAPI.shared.updateLocation(updateRequest)
                } catch {
                    print("❌ Failed to update profile location:", error)
                }

                // Inform AI of the detected city in a natural sentence.
                sendMessage("我目前在\(location.city)")
            case .permissionDenied:
                // User declined location permission: record this in profile and tell AI.
                let updateRequest = LocationUpdateRequest(
                    userId: userId,
                    city: "拒绝提供",
                    latitude: nil,
                    longitude: nil
                )

                do {
                    _ = try await ProfileAPI.shared.updateLocation(updateRequest)
                } catch {
                    print("❌ Failed to update profile location (拒绝提供):", error)
                }

                sendMessage("我不想提供我的所在地")
            case .failedToResolve:
                // Permission granted but system couldn't resolve a city: store "未知"
                // and ask AI to clarify in follow-up messages.
                let updateRequest = LocationUpdateRequest(
                    userId: userId,
                    city: "未知",
                    latitude: nil,
                    longitude: nil
                )

                do {
                    _ = try await ProfileAPI.shared.updateLocation(updateRequest)
                } catch {
                    print("❌ Failed to update profile location (未知):", error)
                }

                sendMessage("系统没有检测到用户的所在地，请在随后的聊天信息中询问")
            }
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

    private func sendCurrentMessage() {
        sendMessage(draftMessage)
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
        draftMessage = ""
        isSending = true
        errorText = nil

        let history: [KYCChatMessage] = messages.map { message in
            let role: KYCChatMessage.Role = (message.sender == .user) ? .user : .assistant
            return KYCChatMessage(role: role, content: message.text)
        }

        let request = KYCMessageRequest(userId: userId, message: trimmed, history: history)

        Task {
            do {
                let response = try await OnboardingAPI.shared.sendKYCMessage(request)
                let aiMessage = Message(text: response.reply, sender: .ai)
                messages.append(aiMessage)

                if response.collectionStatus == "完成" || response.kycCompleted {
                    print("✅ KYC collection completed, navigating to KYCEndView")
                    state.currentStep = .kycEnd
                }
            } catch {
                errorText = "发送失败，请稍后重试。"
                print("❌ KYC message error:", error)
            }
            isSending = false
        }
    }

    private func handleSkip() {
        guard let userId = state.submitUserId else {
            errorText = "缺少用户信息，暂时无法跳过。"
            return
        }

        let request = OnboardingSkipRequest(userId: userId)

        Task {
            do {
                let response = try await OnboardingAPI.shared.skip(request)
                print("✅ KYC skipped:", response.message)
                state.kycEndMode = .skippedIcebreaking
                state.currentStep = .kycEnd
            } catch {
                errorText = "跳过失败，请稍后重试。"
                print("❌ KYC skip error:", error)
            }
        }
    }
}

private extension Notification.Name {
    static let keyboardWillShow = Notification.Name("UIKeyboardWillShowNotification")
    static let keyboardWillHide = Notification.Name("UIKeyboardWillHideNotification")
}

#Preview {
    let state = OnboardingState()
    state.nickname = "测试用户"
    return KYCChatView(state: state)
}
