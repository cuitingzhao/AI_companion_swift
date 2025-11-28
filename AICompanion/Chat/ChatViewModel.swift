import SwiftUI
import Combine

// MARK: - View Models

struct ChatMessage: Identifiable, Equatable {
    enum Sender {
        case user
        case ai
    }

    let id: String
    let serverId: Int?  // Server-side message ID for pagination
    var text: String    // Mutable for streaming updates
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

@MainActor
class ChatViewModel: ObservableObject {
    // MARK: - Properties
    
    let userId: Int
    
    // Data
    @Published var messages: [ChatMessage] = []
    @Published var draftMessage: String = ""
    
    // UI State
    @Published var isSending: Bool = false
    @Published var errorText: String?
    @Published var inputMode: ChatViewInputMode = .text
    
    // Toast
    @Published var toast: ToastData? = nil
    
    // Loading State
    @Published var isInitialLoading: Bool = true
    @Published var isLoadingHistory: Bool = false
    @Published var hasMoreHistory: Bool = false
    private var oldestMessageId: Int? = nil
    private var hasLoadedInitialHistory: Bool = false
    
    // Permission State
    @Published var pendingPermissionAction: PendingClientAction? = nil
    @Published var showPermissionAlert: Bool = false
    @Published var permissionType: PermissionType? = nil
    
    // Goal Wizard State
    @Published var showGoalWizard: Bool = false
    @Published var goalWizardDescription: String?
    @Published var goalWizardSource: String?
    
    // MARK: - Initialization
    
    init(userId: Int) {
        self.userId = userId
    }
    
    // MARK: - Public Methods
    
    /// Pre-warm the chat by starting to load data in background
    /// Call this before user opens chat to reduce perceived loading time
    func prewarm() {
        guard !hasLoadedInitialHistory else { return }
        print("🔥 Pre-warming chat data...")
        loadInitialHistory()
    }
    
    func loadInitialHistory() {
        guard !hasLoadedInitialHistory else { return }
        hasLoadedInitialHistory = true
        
        Task {
            // Fetch greeting and history in parallel for faster loading
            async let greetingTask: ChatMessage? = {
                do {
                    let greetingResponse = try await ChatAPI.shared.fetchGreeting(userId: self.userId)
                    print("👋 Greeting fetched: \(greetingResponse.greeting)")
                    return ChatMessage(text: greetingResponse.greeting, sender: .ai)
                } catch {
                    print("❌ Failed to fetch greeting:", error)
                    return ChatMessage(text: "你好！有什么我可以帮你的吗？", sender: .ai)
                }
            }()
            
            async let historyTask: Void = loadHistory(beforeId: nil)
            
            // Wait for both to complete
            let (greetingMessage, _) = await (greetingTask, historyTask)
            
            // Add date divider if there's history (between history and new greeting)
            if let newestHistoryMessage = messages.first, let lastDate = newestHistoryMessage.createdAt {
                print("📅 Adding date divider after history, newest message date: \(lastDate)")
                messages.append(ChatMessage.divider(date: lastDate))
            } else if !messages.isEmpty {
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
        }
    }
    
    func loadMoreHistory() {
        guard !isLoadingHistory, hasMoreHistory, let beforeId = oldestMessageId else { return }
        
        Task {
            await loadHistory(beforeId: beforeId)
        }
    }
    
    func sendCurrentMessage() {
        guard !isSending else { return }
        let content = draftMessage
        draftMessage = ""
        sendMessage(content)
    }
    
    func sendMessage(_ content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let userMessage = ChatMessage(text: trimmed, sender: .user)
        messages.append(userMessage)
        isSending = true
        errorText = nil
        
        let request = ChatMessageRequest(userId: userId, message: trimmed)
        
        Task {
            do {
                // Use non-streaming endpoint
                let response = try await ChatAPI.shared.sendMessage(request)
                
                // Add AI reply message
                let aiMessage = ChatMessage(text: response.reply, sender: .ai)
                messages.append(aiMessage)
                
                // Handle pending client actions from top-level array
                // Per backend contract: client should read from pending_client_actions at top level
                await handlePendingActions(response.pendingClientActions)
                
            } catch {
                errorText = "消息发送失败，请检查网络后稍后再试。"
                print("❌ Chat message error:", error)
            }
            isSending = false
        }
    }
    
    func requestPermissionAndExecute() async {
        guard let type = permissionType,
              let action = pendingPermissionAction else {
            print("❌ requestPermissionAndExecute: Missing type or action")
            return
        }
        
        print("🔐 Requesting permission for: \(type)")
        let status = await PermissionManager.shared.requestPermission(for: type)
        print("🔐 Permission status returned: \(status)")
        
        if status == .authorized {
            // Retry execution
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
        } else {
            let aiMessage = ChatMessage(text: type.denialMessage, sender: .ai)
            messages.append(aiMessage)
        }
        
        pendingPermissionAction = nil
        permissionType = nil
    }
    
    func toggleInputMode() {
        switch inputMode {
        case .text:
            inputMode = .voice
        case .voice:
            inputMode = .text
        }
    }
    
    func handlePermissionAlertCancel() {
        if let type = permissionType {
            let fallback = ChatMessage(text: type.denialMessage, sender: .ai)
            messages.append(fallback)
        }
        pendingPermissionAction = nil
        permissionType = nil
    }
    
    // MARK: - Private Methods
    
    private func loadHistory(beforeId: Int?) async {
        isLoadingHistory = true
        errorText = nil
        
        do {
            let response = try await ChatAPI.shared.fetchChatHistory(userId: userId, limit: 50, beforeId: beforeId)
            print("📜 Loaded \(response.messages.count) history messages, hasMore: \(response.hasMore)")
            
            // Convert history messages to ChatMessage
            let historyMessages = response.messages.map { msg -> ChatMessage in
                let sender: ChatMessage.Sender = msg.role == "user" ? .user : .ai
                // Backend now returns plain text
                let text = msg.content.trimmingCharacters(in: .whitespacesAndNewlines)
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
    
    private func handlePendingActions(_ actions: [PendingClientAction]) async {
        for action in actions {
            // Handle goal wizard special case
            if action.tool == "goal_wizard" && action.action == "start" {
                let candidateDesc = action.params["candidate_description"]?.value as? String
                let source = action.params["source"]?.value as? String
                
                await MainActor.run {
                    self.goalWizardDescription = candidateDesc
                    self.goalWizardSource = source
                    self.showGoalWizard = true
                }
                
                // Notify backend that wizard is started?
                // Currently NativeToolExecutor doesn't handle goal_wizard, so we handle it here.
                continue
            }
            
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
    
    private func showToast(message: String, type: ToastType) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            toast = ToastData(message: message, type: type)
        }
    }
    
    // MARK: - Helpers
    
    // Cached date formatters for performance
    private static let iso8601FormatterWithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private static let iso8601FormatterBasic: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    private static let simpleDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
    
    /// Parses ISO 8601 date string from backend using cached formatters
    private func parseISO8601Date(_ dateString: String) -> Date? {
        if let date = Self.iso8601FormatterWithFractional.date(from: dateString) {
            return date
        }
        if let date = Self.iso8601FormatterBasic.date(from: dateString) {
            return date
        }
        return Self.simpleDateFormatter.date(from: dateString)
    }
}

// Helper enum for InputMode to be available for ViewModel
enum ChatViewInputMode: Hashable {
    case text
    case voice
}
