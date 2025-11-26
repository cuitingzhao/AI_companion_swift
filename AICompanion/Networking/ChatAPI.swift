import Foundation

public enum ChatAPIError: Error {
    case invalidURL
    case badResponse
    case decodingError
}

@MainActor
public final class ChatAPI {
    public static let shared = ChatAPI()
    public let baseURL: URL

    public init(baseURL: URL = URL(string: "http://localhost:8000")!) {
        self.baseURL = baseURL
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
