import Foundation

public enum ChatStreamEvent {
    case token(String)
    case done(String, [ChatEventPayload])
    case error(String)
}

private struct ChatStreamTokenResponse: Decodable {
    let content: String
}

private struct ChatStreamDoneResponse: Decodable {
    let reply: String
    let events: [ChatEventPayload]?
}

private struct ChatStreamErrorResponse: Decodable {
    let error: String
}

/// Chat API - All endpoints require authentication
@MainActor
public final class ChatAPI {
    public static let shared = ChatAPI()
    private let client = APIClient.shared

    private init() {}

    /// POST /api/v1/chat/message/stream
    /// Stream the AI companion reply token-by-token using Server-Sent Events (SSE).
    /// Note: Tools are disabled in streaming mode.
    public func streamMessage(_ request: ChatMessageRequest) -> AsyncThrowingStream<ChatStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    // Build request with auth header
                    var urlRequest = await client.makeRequest(
                        path: "/api/v1/chat/message/stream",
                        method: "POST",
                        body: try JSONEncoder().encode(request),
                        requiresAuth: true
                    )
                    urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")

                    let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)

                    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                        continuation.finish(throwing: APIError.invalidResponse)
                        return
                    }

                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))
                            guard let data = jsonString.data(using: .utf8) else { continue }

                            // Try to decode as Done event first (has reply field)
                            if let doneResponse = try? JSONDecoder().decode(ChatStreamDoneResponse.self, from: data) {
                                continuation.yield(.done(doneResponse.reply, doneResponse.events ?? []))
                                continuation.finish()
                                return
                            }
                            
                            // Try to decode as Token event (has content field)
                            if let tokenResponse = try? JSONDecoder().decode(ChatStreamTokenResponse.self, from: data) {
                                continuation.yield(.token(tokenResponse.content))
                                continue
                            }
                            
                            // Try as Error
                            if let errorResponse = try? JSONDecoder().decode(ChatStreamErrorResponse.self, from: data) {
                                continuation.yield(.error(errorResponse.error))
                                continuation.finish(throwing: APIError.invalidResponse)
                                return
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    /// POST /api/v1/chat/message
    /// Process a user message in the main companion chat with optional tool calling support.
    public func sendMessage(_ request: ChatMessageRequest, enableTools: Bool = true) async throws -> ChatMessageResponse {
        let path = "/api/v1/chat/message?enable_tools=\(enableTools ? "true" : "false")"
        return try await client.post(path: path, body: request)
    }

    /// GET /api/v1/chat/history
    /// Get paginated chat history for the current user.
    public func fetchChatHistory(limit: Int = 50, beforeId: Int? = nil) async throws -> ChatHistoryResponse {
        var path = "/api/v1/chat/history?limit=\(limit)"
        if let beforeId = beforeId {
            path += "&before_id=\(beforeId)"
        }
        return try await client.get(path: path)
    }

    /// GET /api/v1/chat/greeting
    /// Generate a personalized AI greeting when user opens the chat.
    public func fetchGreeting() async throws -> ChatGreetingResponse {
        return try await client.get(path: "/api/v1/chat/greeting")
    }
    
    // MARK: - Deprecated
    
    @available(*, deprecated, message: "Use fetchChatHistory(limit:beforeId:) - userId derived from token")
    public func fetchChatHistory(userId: Int, limit: Int = 50, beforeId: Int? = nil) async throws -> ChatHistoryResponse {
        return try await fetchChatHistory(limit: limit, beforeId: beforeId)
    }
    
    @available(*, deprecated, message: "Use fetchGreeting() - userId derived from token")
    public func fetchGreeting(userId: Int) async throws -> ChatGreetingResponse {
        return try await fetchGreeting()
    }
}
