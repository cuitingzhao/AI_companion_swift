import Foundation

public enum ChatAPIError: Error {
    case invalidURL
    case badResponse
    case decodingError
}

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

@MainActor
public final class ChatAPI {
    public static let shared = ChatAPI()
    public let baseURL: URL

    public init(baseURL: URL = URL(string: "http://localhost:8000")!) {
        self.baseURL = baseURL
    }

    /// POST /api/v1/chat/message/stream
    /// Stream the AI companion reply token-by-token using Server-Sent Events (SSE).
    /// Note: Tools are disabled in streaming mode.
    public func streamMessage(_ request: ChatMessageRequest) -> AsyncThrowingStream<ChatStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var components = URLComponents()
                    components.scheme = baseURL.scheme
                    components.host = baseURL.host
                    components.port = baseURL.port
                    components.path = "/api/v1/chat/message/stream"

                    guard let url = components.url else {
                        continuation.finish(throwing: ChatAPIError.invalidURL)
                        return
                    }

                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")

                    let encoder = JSONEncoder()
                    urlRequest.httpBody = try encoder.encode(request)

                    let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)

                    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                        continuation.finish(throwing: ChatAPIError.badResponse)
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
                                continuation.finish(throwing: ChatAPIError.badResponse)
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
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/chat/message"
        components.queryItems = [
            URLQueryItem(name: "enable_tools", value: enableTools ? "true" : "false")
        ]

        guard let url = components.url else {
            throw ChatAPIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ChatAPIError.badResponse
        }

        // Debug: Print raw response
        if let rawString = String(data: data, encoding: .utf8) {
            print("🔵 ChatAPI raw response: \(rawString)")
        }

        let decoder = JSONDecoder()
        return try decoder.decode(ChatMessageResponse.self, from: data)
    }

    /// GET /api/v1/chat/history/{user_id}
    /// Get paginated chat history for a user.
    /// - Parameters:
    ///   - userId: User ID
    ///   - limit: Maximum messages to return (1-200), default 50
    ///   - beforeId: Return messages before this message ID (for pagination)
    public func fetchChatHistory(userId: Int, limit: Int = 50, beforeId: Int? = nil) async throws -> ChatHistoryResponse {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/chat/history/\(userId)"

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let beforeId = beforeId {
            queryItems.append(URLQueryItem(name: "before_id", value: String(beforeId)))
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            throw ChatAPIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ChatAPIError.badResponse
        }

        // Debug: Print raw response
        if let rawString = String(data: data, encoding: .utf8) {
            print("🔵 ChatAPI history raw response: \(rawString.prefix(500))...")
        }

        let decoder = JSONDecoder()
        return try decoder.decode(ChatHistoryResponse.self, from: data)
    }

    /// GET /api/v1/chat/greeting/{user_id}
    /// Generate a personalized AI greeting when user opens the chat.
    public func fetchGreeting(userId: Int) async throws -> ChatGreetingResponse {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/chat/greeting/\(userId)"

        guard let url = components.url else {
            throw ChatAPIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ChatAPIError.badResponse
        }

        // Debug: Print raw response
        if let rawString = String(data: data, encoding: .utf8) {
            print("🔵 ChatAPI greeting raw response: \(rawString)")
        }

        let decoder = JSONDecoder()
        return try decoder.decode(ChatGreetingResponse.self, from: data)
    }
}
