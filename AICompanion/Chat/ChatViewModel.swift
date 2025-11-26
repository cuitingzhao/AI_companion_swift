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
    
    // MARK: - Initialization
    
    init(userId: Int) {
        self.userId = userId
    }
    
    // MARK: - Public Methods
    
    func loadInitialHistory() {
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
    
    func requestPermissionAndExecute() async {
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
    
    private func showToast(message: String, type: ToastType) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            toast = ToastData(message: message, type: type)
        }
    }
    
    // MARK: - Helpers
    
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

// Helper enum for InputMode to be available for ViewModel
enum ChatViewInputMode: Hashable {
    case text
    case voice
}
