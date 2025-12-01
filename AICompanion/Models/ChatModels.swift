import Foundation

// MARK: - Request

public struct ChatMessageRequest: Codable {
    public let userId: Int
    public let message: String
    public let images: [String]?  // Base64 data URIs or URLs, max 4 images
    public let modelName: String?

    public init(userId: Int, message: String, images: [String]? = nil, modelName: String? = nil) {
        self.userId = userId
        self.message = message
        self.images = images
        self.modelName = modelName
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case message
        case images
        case modelName = "model_name"
    }
}

// MARK: - Response

public struct ChatMessageResponse: Codable {
    public let reply: String
    public let events: [ChatEventPayload]
    public let toolCallsMade: [ToolCallRecord]
    public let pendingClientActions: [PendingClientAction]

    enum CodingKeys: String, CodingKey {
        case reply
        case events
        case toolCallsMade = "tool_calls_made"
        case pendingClientActions = "pending_client_actions"
    }

    // Custom decoder to handle missing optional fields
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reply = try container.decode(String.self, forKey: .reply)
        events = try container.decodeIfPresent([ChatEventPayload].self, forKey: .events) ?? []
        toolCallsMade = try container.decodeIfPresent([ToolCallRecord].self, forKey: .toolCallsMade) ?? []
        pendingClientActions = try container.decodeIfPresent([PendingClientAction].self, forKey: .pendingClientActions) ?? []
    }
}

public struct ChatEventPayload: Codable {
    public let eventId: Int?
    public let desc: String
    public let isEventNew: Bool
    public let progressNote: String?
    public let priority: String
    public let eventState: String

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case desc
        case isEventNew = "is_event_new"
        case progressNote = "progress_note"
        case priority
        case eventState = "event_state"
    }
}

public struct ToolCallRecord: Codable {
    public let tool: String
    public let arguments: [String: AnyCodable]
    public let result: [String: AnyCodable]
}

// MARK: - Pending Client Action (iOS Native Tools)

public struct PendingClientAction: Codable {
    public let tool: String      // "calendar_manager", "alarm_manager", "health_data", "screen_time"
    public let action: String    // "create_alarm", "create_event", "query_steps", etc.
    public let params: [String: AnyCodable]

    public init(tool: String, action: String, params: [String: AnyCodable]) {
        self.tool = tool
        self.action = action
        self.params = params
    }
}

// MARK: - Chat Greeting Models

public struct ChatGreetingResponse: Codable {
    public let greeting: String
    public let hasPendingFollowups: Bool
    public let isReturningUser: Bool

    enum CodingKeys: String, CodingKey {
        case greeting
        case hasPendingFollowups = "has_pending_followups"
        case isReturningUser = "is_returning_user"
    }
}

// MARK: - Chat History Models

public struct ChatHistoryResponse: Codable {
    public let messages: [ChatHistoryMessage]
    public let hasMore: Bool
    public let oldestId: Int?
    public let conversationId: Int?

    enum CodingKeys: String, CodingKey {
        case messages
        case hasMore = "has_more"
        case oldestId = "oldest_id"
        case conversationId = "conversation_id"
    }
}

public struct ChatHistoryMessage: Codable, Identifiable {
    public let id: Int
    public let role: String
    public let content: String
    public let createdAt: String
    public let toolCalls: [AnyCodable]?
    public let attachments: [String]?  // Image URLs attached to this message

    enum CodingKeys: String, CodingKey {
        case id
        case role
        case content
        case createdAt = "created_at"
        case toolCalls = "tool_calls"
        case attachments
    }
}

// MARK: - AnyCodable Helper

public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable cannot decode value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable cannot encode value"))
        }
    }
}
