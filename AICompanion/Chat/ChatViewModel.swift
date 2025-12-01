import SwiftUI
import Combine
import UIKit

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
    let images: [UIImage]?  // Attached images for current session (not persisted)
    let imageURLs: [String]?  // Image URLs from history (persisted)

    init(text: String, sender: Sender, serverId: Int? = nil, createdAt: Date? = nil, isDivider: Bool = false, images: [UIImage]? = nil, imageURLs: [String]? = nil) {
        self.id = serverId.map { "server-\($0)" } ?? UUID().uuidString
        self.serverId = serverId
        self.text = text
        self.sender = sender
        self.createdAt = createdAt
        self.isDivider = isDivider
        self.images = images
        self.imageURLs = imageURLs
    }
    
    /// Creates a date divider message
    static func divider(date: Date) -> ChatMessage {
        ChatMessage(text: "", sender: .ai, createdAt: date, isDivider: true)
    }
    
    // Equatable conformance - compare by id only since UIImage isn't Equatable
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id && lhs.text == rhs.text && lhs.isDivider == rhs.isDivider
    }
}

@MainActor
class ChatViewModel: ObservableObject {
    // MARK: - Properties
    
    let userId: Int
    
    // Data
    @Published var messages: [ChatMessage] = []
    @Published var draftMessage: String = ""
    @Published var selectedImages: [UIImage] = []  // Images pending to be sent
    
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
        guard !hasLoadedInitialHistory else { 
            print("📜 Initial history already loaded, skipping")
            return 
        }
        hasLoadedInitialHistory = true
        print("📜 Loading initial history for user \(userId)...")
        
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
            
            print("📜 History loaded, messages count: \(messages.count)")
            
            // Add date divider if there's history (between history and new greeting)
            if let newestHistoryMessage = messages.last, let lastDate = newestHistoryMessage.createdAt {
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
            print("📜 Initial loading complete, total messages: \(messages.count)")
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
        let content = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Require text for all messages (including those with images)
        guard !content.isEmpty else {
            if !selectedImages.isEmpty {
                showToast(message: "请输入消息内容", type: .error)
            }
            return
        }
        
        let images = selectedImages
        draftMessage = ""
        selectedImages = []
        sendMessage(content, images: images)
    }
    
    func sendMessage(_ content: String, images: [UIImage] = []) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        // Require text for all messages
        guard !trimmed.isEmpty else { return }
        
        let userMessage = ChatMessage(text: trimmed, sender: .user, images: images.isEmpty ? nil : images)
        messages.append(userMessage)
        isSending = true
        errorText = nil
        
        Task {
            do {
                // Step 1: Upload images to OSS first (if any)
                var imageURLs: [String]? = nil
                if !images.isEmpty {
                    imageURLs = []
                    for image in images {
                        if let base64Data = convertImageToBase64DataURI(image) {
                            let uploadResponse = try await MediaAPI.shared.uploadImage(userId: userId, imageData: base64Data)
                            imageURLs?.append(uploadResponse.url)
                            print("📷 Image uploaded: \(uploadResponse.url)")
                        }
                    }
                }
                
                // Step 2: Send chat message with image URLs
                let request = ChatMessageRequest(userId: userId, message: trimmed, images: imageURLs)
                let response = try await ChatAPI.shared.sendMessage(request)
                
                // Add AI reply message
                let aiMessage = ChatMessage(text: response.reply, sender: .ai)
                messages.append(aiMessage)
                
                // Handle pending client actions from top-level array
                // Per backend contract: client should read from pending_client_actions at top level
                await handlePendingActions(response.pendingClientActions)
                
            } catch let error as MediaAPIError {
                switch error {
                case .uploadFailed(let message):
                    errorText = message
                default:
                    errorText = "图片上传失败，请稍后再试。"
                }
                print("❌ Media upload error:", error)
            } catch {
                errorText = "消息发送失败，请检查网络后稍后再试。"
                print("❌ Chat message error:", error)
            }
            isSending = false
        }
    }
    
    func addImage(_ image: UIImage) {
        // Only allow 1 image per message
        guard selectedImages.isEmpty else {
            showToast(message: "每条消息只能添加1张图片", type: .error)
            return
        }
        selectedImages.append(image)
    }
    
    func removeImage(at index: Int) {
        guard index >= 0 && index < selectedImages.count else { return }
        selectedImages.remove(at: index)
    }
    
    func clearImages() {
        selectedImages.removeAll()
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
                // Include attachments (image URLs) from history
                let imageURLs = msg.attachments
                print("📜 Message \(msg.id): role=\(msg.role), attachments=\(imageURLs ?? [])")
                return ChatMessage(text: text, sender: sender, serverId: msg.id, createdAt: timestamp, imageURLs: imageURLs)
            }
            
            if beforeId == nil {
                // Initial load - replace messages
                messages = historyMessages
                print("📜 Set messages to \(historyMessages.count) history messages")
            } else {
                // Pagination - prepend older messages
                messages.insert(contentsOf: historyMessages, at: 0)
                print("📜 Prepended \(historyMessages.count) older messages")
            }
            
            hasMoreHistory = response.hasMore
            oldestMessageId = response.oldestId
        } catch let error as DecodingError {
            print("❌ Failed to decode chat history: \(error)")
            if case .keyNotFound(let key, let context) = error {
                print("❌ Missing key: \(key.stringValue), path: \(context.codingPath)")
            } else if case .typeMismatch(let type, let context) = error {
                print("❌ Type mismatch: expected \(type), path: \(context.codingPath)")
            }
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
    
    /// Converts UIImage to base64 data URI for API request
    private func convertImageToBase64DataURI(_ image: UIImage) -> String? {
        // Resize image aggressively (max 512px on longest side for faster upload)
        let maxDimension: CGFloat = 256
        var targetImage = image
        
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let scale = maxDimension / max(image.size.width, image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            if let resizedImage = UIGraphicsGetImageFromCurrentImageContext() {
                targetImage = resizedImage
            }
            UIGraphicsEndImageContext()
        }
        
        // Convert to JPEG with 0.6 quality for aggressive compression
        guard let imageData = targetImage.jpegData(compressionQuality: 0.6) else {
            print("❌ Failed to convert image to JPEG data")
            return nil
        }
        
        let base64String = imageData.base64EncodedString()
        return "data:image/jpeg;base64,\(base64String)"
    }
}

// Helper enum for InputMode to be available for ViewModel
enum ChatViewInputMode: Hashable {
    case text
    case voice
}
