import SwiftUI
import Combine

public struct ChatView: View {
    private let userId: Int
    @Environment(\.dismiss) private var dismiss

    @State private var messages: [ChatMessage] = []
    @State private var draftMessage: String = ""
    @State private var isSending: Bool = false
    @State private var errorText: String?
    @State private var keyboardHeight: CGFloat = 0
    @State private var inputMode: InputMode = .text

    // Permission request state
    @State private var pendingPermissionAction: PendingClientAction? = nil
    @State private var showPermissionAlert: Bool = false
    @State private var permissionType: PermissionType? = nil

    // Toast state
    @State private var toast: ToastData? = nil

    // Loading state
    @State private var isInitialLoading: Bool = true
    @State private var isLoadingHistory: Bool = false
    @State private var hasMoreHistory: Bool = false
    @State private var oldestMessageId: Int? = nil
    @State private var hasLoadedInitialHistory: Bool = false

    // Scroll state
    @State private var scrollProxy: ScrollViewProxy? = nil
    private let loadingIndicatorId = "loading-indicator"

    public init(userId: Int) {
        self.userId = userId
    }

    private struct ChatMessage: Identifiable, Equatable {
        enum Sender {
            case user
            case ai
        }

        let id: String
        let serverId: Int?  // Server-side message ID for pagination
        let text: String
        let sender: Sender
        let createdAt: Date?  // Timestamp for divider display
        let isDivider: Bool  // Special flag for date divider

        init(text: String, sender: Sender, serverId: Int? = nil, createdAt: Date? = nil, isDivider: Bool = false) {
            self.id = serverId.map { "server-\($0)" } ?? UUID().uuidString
            self.serverId = serverId
            self.text = text
            self.sender = sender
            self.createdAt = createdAt
            self.isDivider = isDivider
        }

        /// Creates a date divider message
        static func divider(date: Date) -> ChatMessage {
            ChatMessage(text: "", sender: .ai, createdAt: date, isDivider: true)
        }
    }

    private enum InputMode: Hashable {
        case text
        case voice
    }

    public var body: some View {
        GeometryReader { geometry in
            let containerWidth = geometry.size.width - 48

            ZStack(alignment: .top) {
                AppColors.gradientBackground
                    .ignoresSafeArea()

                Image("star_bg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .opacity(0.6)

                VStack(spacing: 0) {
                    chatHeader

                    // White card container matching OnboardingScaffold style
                    ZStack(alignment: .top) {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)

                        if isInitialLoading {
                            // Loading state while fetching greeting
                            VStack(spacing: 16) {
                                Spacer()
                                ProgressView()
                                    .tint(AppColors.purple)
                                Text("正在加载...")
                                    .font(AppFonts.body)
                                    .foregroundStyle(AppColors.textBlack)
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 16) {
                                ScrollViewReader { proxy in
                                    ScrollView {
                                        LazyVStack(spacing: 12) {
                                            // Load more button at top
                                            if hasMoreHistory {
                                                Button(action: loadMoreHistory) {
                                                    if isLoadingHistory {
                                                        ProgressView()
                                                            .tint(AppColors.purple)
                                                    } else {
                                                        Text("加载更多")
                                                            .font(AppFonts.caption)
                                                            .foregroundStyle(AppColors.purple)
                                                    }
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .disabled(isLoadingHistory)
                                            }

                                            ForEach(messages) { message in
                                                if message.isDivider {
                                                    dateDivider(date: message.createdAt)
                                                        .id(message.id)
                                                } else {
                                                    chatBubble(for: message)
                                                        .id(message.id)
                                                }
                                            }

                                            if isSending {
                                                HStack {
                                                    ChatBubbleLoadingIndicator(
                                                        isActive: $isSending,
                                                        subtitle: nil
                                                    )
                                                    Spacer()
                                                }
                                                .id(loadingIndicatorId)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    .onChange(of: messages.count) { _, _ in
                                        scrollToBottom(proxy: proxy)
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
                                    .onAppear {
                                        scrollProxy = proxy
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
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                        }
                    }
                    .frame(width: containerWidth)
                    .frame(maxHeight: .infinity)
                    .padding(.bottom, 28)
                }
            }
        }
        .padding(.bottom, keyboardHeight)
        .animation(.easeOut(duration: 0.25), value: keyboardHeight)
        .onAppear(perform: loadInitialHistory)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UIKeyboardWillShowNotification"))) { notification in
            if let frameValue = notification.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? NSValue {
                keyboardHeight = frameValue.cgRectValue.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UIKeyboardWillHideNotification"))) { _ in
            keyboardHeight = 0
        }
        .navigationBarHidden(true)
        .toast($toast)
        .alert("需要权限", isPresented: $showPermissionAlert) {
            Button("允许") {
                Task {
                    await requestPermissionAndExecute()
                }
            }
            Button("取消", role: .cancel) {
                if let type = permissionType {
                    let fallback = ChatMessage(text: type.denialMessage, sender: .ai)
                    messages.append(fallback)
                }
                pendingPermissionAction = nil
                permissionType = nil
            }
        } message: {
            if let type = permissionType {
                Text(type.contextMessage)
            }
        }
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: 16) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.textBlack)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text("AI 伙伴")
                    .font(AppFonts.subtitle)
                    .foregroundStyle(AppColors.textBlack)

                Text("随时与我聊天")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.neutralGray)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Date Divider

    private func dateDivider(date: Date?) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(AppColors.neutralGray.opacity(0.5))
                .frame(height: 1)
                .frame(maxWidth: .infinity)

            Text(formatDividerDate(date))
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.neutralGray)
                .lineLimit(1)
                .fixedSize()

            Rectangle()
                .fill(AppColors.neutralGray.opacity(0.5))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    private func formatDividerDate(_ date: Date?) -> String {
        guard let date = date else { return "上次对话" }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return "上次对话 · " + formatter.string(from: date)
    }

    // MARK: - Chat Bubble

    private func chatBubble(for message: ChatMessage) -> some View {
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

    // MARK: - Input Area

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
        .disabled(isSending)
    }

    // MARK: - Actions

    private func loadInitialHistory() {
        guard !hasLoadedInitialHistory else { return }
        hasLoadedInitialHistory = true

        Task {
            // First, fetch personalized greeting
            var greetingMessage: ChatMessage?
            do {
                let greetingResponse = try await ChatAPI.shared.fetchGreeting(userId: userId)
                print("👋 Greeting fetched: \(greetingResponse.greeting)")
                greetingMessage = ChatMessage(text: greetingResponse.greeting, sender: .ai)
            } catch {
                print("❌ Failed to fetch greeting:", error)
                // Fallback to default greeting
                let fallbackText = "你好！有什么我可以帮你的吗？"
                greetingMessage = ChatMessage(text: fallbackText, sender: .ai)
            }

            // Then load chat history
            await loadHistory(beforeId: nil)

            // Add date divider if there's history (between history and new greeting)
            // Use first message's timestamp since history is returned newest-first
            if let newestHistoryMessage = messages.first, let lastDate = newestHistoryMessage.createdAt {
                print("📅 Adding date divider after history, newest message date: \(lastDate)")
                messages.append(ChatMessage.divider(date: lastDate))
            } else if !messages.isEmpty {
                // If history exists but no timestamp, use current time as fallback
                print("📅 Adding date divider with current time (no timestamp in history)")
                messages.append(ChatMessage.divider(date: Date()))
            } else {
                print("📅 No history loaded, skipping divider")
            }

            // Add greeting as the last message (most recent)
            if let greeting = greetingMessage {
                messages.append(greeting)
            }

            // Done loading
            isInitialLoading = false

            // Scroll to bottom after a short delay to ensure view is rendered
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let proxy = scrollProxy, let lastId = messages.last?.id {
                    withAnimation {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func loadMoreHistory() {
        guard !isLoadingHistory, hasMoreHistory, let beforeId = oldestMessageId else { return }

        Task {
            await loadHistory(beforeId: beforeId)
        }
    }

    @MainActor
    private func loadHistory(beforeId: Int?) async {
        isLoadingHistory = true
        errorText = nil

        do {
            let response = try await ChatAPI.shared.fetchChatHistory(userId: userId, limit: 50, beforeId: beforeId)
            print("📜 Loaded \(response.messages.count) history messages, hasMore: \(response.hasMore)")

            // Convert history messages to ChatMessage
            let historyMessages = response.messages.map { msg -> ChatMessage in
                let sender: ChatMessage.Sender = msg.role == "user" ? .user : .ai
                // Extract actual reply text for AI messages (handles nested JSON)
                let text = sender == .ai ? extractReplyText(from: msg.content) : msg.content
                let timestamp = parseISO8601Date(msg.createdAt)
                return ChatMessage(text: text, sender: sender, serverId: msg.id, createdAt: timestamp)
            }

            if beforeId == nil {
                // Initial load - replace messages
                messages = historyMessages
            } else {
                // Pagination - prepend older messages
                messages.insert(contentsOf: historyMessages, at: 0)
            }

            hasMoreHistory = response.hasMore
            oldestMessageId = response.oldestId
        } catch {
            print("❌ Failed to load chat history:", error)
            // Don't show error for initial load if no history exists
            if beforeId != nil {
                errorText = "加载历史消息失败"
            }
        }

        isLoadingHistory = false
    }

    private func sendCurrentMessage() {
        guard !isSending else { return }
        let content = draftMessage
        draftMessage = ""
        sendMessage(content)
    }

    private func sendMessage(_ content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMessage = ChatMessage(text: trimmed, sender: .user)
        messages.append(userMessage)
        isSending = true
        errorText = nil

        let request = ChatMessageRequest(userId: userId, message: trimmed)

        Task {
            do {
                let response = try await ChatAPI.shared.sendMessage(request)
                print("🟣 Chat message response received")
                print("🟣 Raw reply: \(response.reply)")

                // Extract the actual reply text, handling potential nested JSON in reply
                let replyText = extractReplyText(from: response.reply)
                if !replyText.isEmpty {
                    let aiMessage = ChatMessage(text: replyText, sender: .ai)
                    messages.append(aiMessage)
                }

                // Log tool calls if any
                if !response.toolCallsMade.isEmpty {
                    print("🔧 Tool calls made: \(response.toolCallsMade.count)")
                    for toolCall in response.toolCallsMade {
                        print("  - Tool: \(toolCall.tool)")
                    }
                }

                // Log events if any
                if !response.events.isEmpty {
                    print("📅 Events created/updated: \(response.events.count)")
                }

                // Handle pending client actions (iOS native tools)
                // First check top-level pending_client_actions
                var actionsToExecute = response.pendingClientActions
                print("📱 Top-level pending client actions: \(actionsToExecute.count)")

                // Also extract from tool_calls_made[].result.result.pending_client_action (backend workaround)
                for toolCall in response.toolCallsMade {
                    // Path: result -> result -> pending_client_action
                    if let nestedResult = toolCall.result["result"]?.value as? [String: Any],
                       let resultDict = nestedResult["pending_client_action"] as? [String: Any],
                       let tool = resultDict["tool"] as? String,
                       let action = resultDict["action"] as? String,
                       let paramsDict = resultDict["params"] as? [String: Any] {
                        print("📱 Found nested action in tool_calls_made: \(tool).\(action)")
                        let params = paramsDict.mapValues { AnyCodable($0) }
                        let pendingAction = PendingClientAction(tool: tool, action: action, params: params)
                        actionsToExecute.append(pendingAction)
                    }
                }

                print("📱 Total actions to execute: \(actionsToExecute.count)")
                if !actionsToExecute.isEmpty {
                    for action in actionsToExecute {
                        print("📱 Action: \(action.tool).\(action.action) with params: \(action.params)")
                    }
                    await handlePendingActions(actionsToExecute)
                }
            } catch {
                errorText = "消息发送失败，请检查网络后稍后再试。"
                print("❌ Chat message error:", error)
            }
            isSending = false
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

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = messages.last?.id {
            withAnimation {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }

    // MARK: - Toast Helper

    private func showToast(message: String, type: ToastType) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            toast = ToastData(message: message, type: type)
        }
    }

    // MARK: - Native Tool Execution

    @MainActor
    private func handlePendingActions(_ actions: [PendingClientAction]) async {
        for action in actions {
            let result = await NativeToolExecutor.shared.execute(action)

            switch result {
            case .success(let message):
                let aiMessage = ChatMessage(text: message, sender: .ai)
                messages.append(aiMessage)
                // Show toast for calendar actions
                if action.tool == "calendar_manager" {
                    showToast(message: "日历已更新", type: .success)
                }

            case .permissionRequired(let type):
                // Show permission alert
                pendingPermissionAction = action
                permissionType = type
                showPermissionAlert = true
                return // Wait for user response

            case .permissionDenied(let fallbackMessage):
                let aiMessage = ChatMessage(text: fallbackMessage, sender: .ai)
                messages.append(aiMessage)

            case .failed(let error):
                print("❌ Native tool execution failed: \(error)")
                let aiMessage = ChatMessage(text: "抱歉，操作失败了：\(error)", sender: .ai)
                messages.append(aiMessage)
            }
        }
    }

    @MainActor
    private func requestPermissionAndExecute() async {
        guard let type = permissionType,
              let action = pendingPermissionAction else { return }

        let status = await PermissionManager.shared.requestPermission(for: type)

        if status == .authorized {
            // Retry execution
            let result = await NativeToolExecutor.shared.execute(action)
            switch result {
            case .success(let message):
                let aiMessage = ChatMessage(text: message, sender: .ai)
                messages.append(aiMessage)
            case .failed(let error):
                let aiMessage = ChatMessage(text: "操作失败：\(error)", sender: .ai)
                messages.append(aiMessage)
            default:
                break
            }
        } else {
            let aiMessage = ChatMessage(text: type.denialMessage, sender: .ai)
            messages.append(aiMessage)
        }

        pendingPermissionAction = nil
        permissionType = nil
    }

    /// Extracts the actual reply text from the response.
    /// Handles cases where the backend returns nested JSON in the reply field.
    private func extractReplyText(from reply: String) -> String {
        let trimmed = reply.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if reply starts with "json" prefix (malformed response)
        var jsonString = trimmed
        if trimmed.lowercased().hasPrefix("json") {
            jsonString = String(trimmed.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Try to parse as JSON and extract "reply" field
        if jsonString.hasPrefix("{"),
           let data = jsonString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let nestedReply = json["reply"] as? String {
            print("🟡 Extracted nested reply from JSON")
            return nestedReply.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Return original if not nested JSON
        return trimmed
    }

    /// Parses ISO 8601 date string from backend
    private func parseISO8601Date(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            return date
        }
        // Try simple format without timezone
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return simpleFormatter.date(from: dateString)
    }
}

#Preview {
    ChatView(userId: 1)
}
