# Chat API Documentation

Source file: [`app/api/v1/endpoints/chat.py`](../app/api/v1/endpoints/chat.py)

## 1. POST `/api/v1/chat/message`

Process a user message in the main companion chat with optional tool calling support.

### Description

This is the primary chat endpoint for the AI companion. It:

1. **Builds context** from user profile, Bazi chart, personality analysis
2. **Injects tool capabilities** (L0 index) into the system prompt
3. **Calls AI model** with tool definitions (L1 schemas) if enabled
4. **Executes tools** automatically when AI requests them (e.g., ganzhi calculator, goal manager)
5. **Returns response** with reply, tool execution records, and any `pending_client_actions` for the client to handle

### Query Parameters

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `enable_tools` | boolean | `true` | Enable tool calling capabilities. Set to `false` to disable tools. |

### Request Body — [`ChatMessageRequest`](../app/schemas/chat.py)

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `user_id` | integer | Yes | User ID (must be > 0). |
| `message` | string | Yes | User's chat message (1-4000 characters). |
| `model_name` | string | No | Optional model override. Defaults to `MODEL_MAIN_CHAT` env var or `deepseek-chat`. |

### Response — [`ChatMessageResponse`](../app/schemas/chat.py)

| Field | Type | Description |
| --- | --- | --- |
| `reply` | string | AI companion's reply to the user. |
| `tool_calls_made` | array of `ToolCallRecord` | Tools called during this chat turn. Empty if no tools invoked. |
| `pending_client_actions` | array of `PendingClientAction` | Actions for iOS client to execute locally (calendar, alarm, goal wizard, etc.). |

#### `ToolCallRecord` Structure

| Field | Type | Description |
| --- | --- | --- |
| `tool` | string | Name of the tool that was called. |
| `arguments` | object | Arguments passed to the tool. |
| `result` | object | Result returned by the tool execution. |

#### `PendingClientAction` Structure

| Field | Type | Description |
| --- | --- | --- |
| `tool` | string | Name of the client-side action source (e.g., `calendar_manager`, `alarm_manager`, `goal_wizard`). |
| `action` | string | Action to perform (e.g., `create_event`, `create_alarm`, `start`). |
| `params` | object | Parameters for the action. |

### Available Tools

When `enable_tools=true`, the AI can call these tools:

| Tool Name | Description | Use Case | Execution |
| --- | --- | --- | --- |
| `ganzhi_calculator` | 计算指定日期的天干地支信息 | 用户询问运势、流年流月时 | Backend |
| `goal_manager` | 管理用户的目标、里程碑和任务 | 用户查询或更新目标进度时 | Backend |
| `goal_wizard` | 启动目标设定向导（客户端多步流程） | 用户明确表达想认真设定/调整目标，并同意进入向导时 | Client（通过 `pending_client_actions` 触发向导 UI） |
| `web_search` | 搜索互联网获取最新信息 | 用户询问新闻、实时信息时 | Backend (Kimi web_search agent, Tavily fallback) |
| `calendar_manager` | 管理日历日程 | 用户创建/查看日程时 | iOS Client |
| `alarm_manager` | 创建和管理闹钟 | 用户设置闹钟时 | iOS Client |
| `health_data` | 查询健康数据 | 用户询问步数/睡眠/运动时 | iOS Client |
| `screen_time` | 查询屏幕使用时间 | 用户询问手机使用情况时 | iOS Client |

#### `ganzhi_calculator` Arguments

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| `date` | string | No | Date in YYYY-MM-DD format. Defaults to today. |
| `time_unit` | string | Yes | `"day"`, `"month"`, or `"year"` for pillar type. |

#### `goal_manager` Arguments

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| `action` | string | Yes | One of: `list_goals`, `get_goal_detail`, `update_goal`, `update_milestone`, `update_task`, `create_task`. |
| `goal_id` | string | Depends | Required for most actions except `list_goals`. |
| `milestone_id` | string | Depends | Required for milestone/task operations. |
| `task_id` | string | Depends | Required for `update_task`. |
| `updates` | object | Depends | Fields to update or create. |

#### `goal_wizard` Arguments

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| `candidate_description` | string | Yes | AI 总结的目标候选描述，1–2 句自然语言，用于在客户端向导中预填。 |
| `source` | string | No | 触发来源，例如 `"chat"` 或 `"manual"`。默认由后端填为 `"chat"`。 |

#### `web_search` Arguments

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| `query` | string | Yes | Search query. |
| `search_depth` | string | No | `"basic"` or `"advanced"`. Default: `"basic"`. |
| `max_results` | integer | No | Number of results (1-10). Default: 5. |

#### iOS Native Tools (calendar_manager, alarm_manager, health_data, screen_time)

These tools return `pending_client_actions` instead of executing directly. The iOS client should:
1. Check if user has granted required permissions
2. Request permission if needed
3. Execute the action using native iOS APIs
4. Optionally report result back to the chat

See `PendingClientAction` structure above for the response format.

#### Goal Wizard Trigger (goal_wizard)

The `goal_wizard` tool is a **trigger** for a client-side goal setting wizard. It does not
create or update goals directly. Instead, the backend returns a `pending_client_action` like:

```json
{
  "tool": "goal_wizard",
  "action": "start",
  "params": {
    "candidate_description": "在一年内坚持锻炼，让体脂降到20%左右",
    "source": "chat",
    "user_id": "1"
  }
}
```

The mobile app should:
1. Inspect `pending_client_actions` in the `ChatMessageResponse`.
2. When it finds an action with `tool = "goal_wizard"` and `action = "start"`,
   open the dedicated goal wizard UI.
3. Use `candidate_description` to pre-fill the wizard with the AI's understanding
   of the goal candidate.

### Example Request

```bash
curl -X POST "http://localhost:8000/api/v1/chat/message?enable_tools=true" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "message": "今天运势怎么样？"
  }'
```

### Example Response (with tool call)

```json
{
  "reply": "让我帮你查一下今天的干支信息。今天是乙巳日，巳火藏丙、庚、戊。从八字角度来看，今天火气较旺...",
  "tool_calls_made": [
    {
      "tool": "ganzhi_calculator",
      "arguments": {
        "time_unit": "day"
      },
      "result": {
        "success": true,
        "result": {
          "label": "日柱",
          "ganzhi": "乙巳",
          "heavenly_stem": "乙",
          "earthly_branch": "巳",
          "hidden_stems": ["丙", "庚", "戊"],
          "query_date": "2025-11-25",
          "time_unit": "day"
        }
      }
    }
  ]
}
```

### Example Response (with iOS native tool)

```json
{
  "reply": "好的，我来帮你设置明早7点的闹钟。",
  "tool_calls_made": [
    {
      "tool": "alarm_manager",
      "arguments": {
        "action": "create_alarm",
        "time": "07:00",
        "label": "起床"
      },
      "result": {
        "status": "pending_client_action",
        "message": "闹钟操作 'create_alarm' 已准备好，等待客户端执行",
        "pending_client_action": {
          "tool": "alarm_manager",
          "action": "create_alarm",
          "params": {
            "time": "07:00",
            "label": "起床"
          }
        }
      }
    }
  ],
  "pending_client_actions": [
    {
      "tool": "alarm_manager",
      "action": "create_alarm",
      "params": {
        "time": "07:00",
        "label": "起床"
      }
    }
  ]
}
```

### Example Response (with goal wizard trigger)

```json
{
  "reply": "听起来这是一个对你很重要的长期目标。如果你愿意，我们可以用一个小向导一步步帮你把这个目标理清楚。",
  "tool_calls_made": [
    {
      "tool": "goal_wizard",
      "arguments": {
        "candidate_description": "在一年内坚持锻炼，让体脂降到20%左右",
        "source": "chat"
      },
      "result": {
        "status": "pending_client_action",
        "message": "目标设定向导已准备好，等待客户端执行",
        "pending_client_action": {
          "tool": "goal_wizard",
          "action": "start",
          "params": {
            "candidate_description": "在一年内坚持锻炼，让体脂降到20%左右",
            "source": "chat",
            "user_id": "1"
          }
        }
      }
    }
  ],
  "pending_client_actions": [
    {
      "tool": "goal_wizard",
      "action": "start",
      "params": {
        "candidate_description": "在一年内坚持锻炼，让体脂降到20%左右",
        "source": "chat",
        "user_id": "1"
      }
    }
  ]
}
```

### Example Response (simple reply)

```json
{
  "reply": "哈哈，今天心情不错嘛！有什么开心的事情想分享吗？😊",
  "tool_calls_made": [],
  "pending_client_actions": []
}
```

### Errors

| Status Code | Description |
| --- | --- |
| `422 Unprocessable Entity` | Invalid request body (missing fields, invalid types). |
| `500 Internal Server Error` | AI model error or unexpected failure. |

### Notes

1. **Tool Execution Loop**: When AI decides to use a tool, the system automatically executes it and feeds the result back to the AI. This may happen multiple times (up to 2 rounds) before a final response.

2. **Follow-up Memory**: Follow-up events are managed by an offline batch job, not during chat. The chat agent is aware of active follow-up events for context but does not create or update them in real-time.

3. **Context Building**: The system automatically includes:
   - User profile (nickname, age, gender, personality)
   - Bazi chart information (if available)
   - Active follow-up events due for today
   - **Recent conversation history** (last 10 messages for continuity)

4. **Model Selection**: Default model is `deepseek-chat`. Override via `model_name` in request or `MODEL_MAIN_CHAT` environment variable.

5. **Message Persistence**: All user and assistant messages are automatically saved to the conversation history.

---

## 1.1 Streaming Variant: POST `/api/v1/chat/message/stream`

Stream the AI companion reply token-by-token using **Server-Sent Events (SSE)**.

This endpoint shares the same request body as `POST /api/v1/chat/message` but
returns a streaming response instead of a single JSON object.

### Description

This streaming endpoint:

1. Builds the same rich system prompt (user profile, Bazi, goals, followups).
2. **Disables backend tool execution in v1** to keep the stream simple and
   predictable – the model focuses purely on generating a conversational reply.
3. Streams tokens as they are generated by the model via SSE events.
4. On completion, persists both the user message and the final assistant reply
   into the conversation history.

Use this when you want a more responsive chat UI where the user can see the
assistant typing in real time.

### Request

- **Method:** `POST`
- **Path:** `/api/v1/chat/message/stream`
- **Headers:**
  - `Content-Type: application/json`
  - `Accept: text/event-stream`
- **Body:** `ChatMessageRequest` (same as `/message`)

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `user_id` | integer | Yes | User ID (must be > 0). |
| `message` | string | Yes | User's chat message (1-4000 characters). |
| `model_name` | string | No | Optional model override. Defaults to `MODEL_MAIN_CHAT` env var or `deepseek-chat`. |

### Response — SSE Event Stream

- **Content-Type:** `text/event-stream`
- The response is a sequence of SSE events separated by blank lines.

#### Event Types

| Event | Description | Data Payload Example |
| --- | --- | --- |
| `token` | A partial piece of the assistant reply. Append `content` to the UI buffer. | `{"content": "你好"}` |
| `done` | Final event with the full reply and optional `events` array. | `{"reply": "完整回复...", "events": []}` |
| `error` | Indicates a failure during streaming. | `{"error": "Internal server error"}` |

##### `token` Events

```text
event: token
data: {"content": "你好"}

event: token
data: {"content": "，我是你的AI伙伴"}
```

The client should append each `content` value to the on-screen message as it
arrives.

##### `done` Event

```text
event: done
data: {
  "reply": "你好，我是你的 AI 伙伴，很高兴认识你！",
  "events": []
}
```

- `reply`: Final assistant reply string (may be derived from structured JSON
  `{ reply, events }` when the model follows the contract).
- `events`: Optional follow-up memory payload, same structure as
  `ChatEventPayload` used in `/message`.

##### `error` Event

```text
event: error
data: {"error": "Configuration for model 'xxx' not found."}
```

The client should treat this as a terminal failure for the stream.

### Behavior and Limitations

- **No tools in v1:**
  - The backend passes `tools=None` to the model in streaming mode.
  - The prompt explicitly tells the model that tools are not available in this
    mode.
  - If you need tool execution (e.g., web_search, calendar, alarm), you should
    use the non-streaming `POST /api/v1/chat/message` endpoint.

- **Message persistence:**
  - On the `done` event, the backend saves:
    - The user message (role `user`).
    - The final assistant reply (role `assistant`) with token counts when
      available.

- **Structured JSON output:**
  - If the model returns a JSON object like `{ "reply": "...", "events": [...] }`
    as the final text, the backend will parse it and expose:
    - `reply`: from the JSON.
    - `events`: from the JSON.
  - If parsing fails, the raw text is used as `reply` and `events` defaults to `[]`.

### Example Streaming Request (curl)

```bash
curl -N \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{
    "user_id": 1,
    "message": "简单自我介绍一下吧"
  }' \
  http://localhost:8000/api/v1/chat/message/stream
```

The `-N` flag tells `curl` to disable buffering so you can see tokens as they arrive.

---

## 2. GET `/api/v1/chat/history/{user_id}`

Get paginated chat history for a user.

### Description

Returns chat messages in chronological order (oldest first). Supports cursor-based pagination for loading older messages.

### Path Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| `user_id` | integer | User ID |

### Query Parameters

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `limit` | integer | `50` | Maximum messages to return (1-200). |
| `before_id` | integer | `null` | Return messages before this message ID (for pagination). |

### Response — [`ChatHistoryResponse`](../app/schemas/chat.py)

| Field | Type | Description |
| --- | --- | --- |
| `messages` | array of `ChatHistoryMessage` | Messages in chronological order (oldest first). |
| `has_more` | boolean | Whether there are more messages before the returned set. |
| `oldest_id` | integer \| null | ID of the oldest message returned (use as `before_id` for next page). |
| `conversation_id` | integer \| null | ID of the main chat conversation. |

#### `ChatHistoryMessage` Structure

| Field | Type | Description |
| --- | --- | --- |
| `id` | integer | Message ID. |
| `role` | string | Message role: `"user"` or `"assistant"`. |
| `content` | string | Message content. |
| `created_at` | string (ISO datetime) | When the message was created. |
| `tool_calls` | array \| null | Tool calls made during this message (if any). |

### Example Request

```bash
# Get latest 50 messages
curl "http://localhost:8000/api/v1/chat/history/1"

# Get 20 messages before message ID 100
curl "http://localhost:8000/api/v1/chat/history/1?limit=20&before_id=100"
```

### Example Response

```json
{
  "messages": [
    {
      "id": 95,
      "role": "user",
      "content": "今天心情不太好",
      "created_at": "2025-11-25T10:30:00",
      "tool_calls": null
    },
    {
      "id": 96,
      "role": "assistant",
      "content": "怎么了？发生什么事了吗？我在这里听你说 😊",
      "created_at": "2025-11-25T10:30:05",
      "tool_calls": null
    },
    {
      "id": 97,
      "role": "user",
      "content": "工作压力太大了",
      "created_at": "2025-11-25T10:31:00",
      "tool_calls": null
    },
    {
      "id": 98,
      "role": "assistant",
      "content": "工作压力大确实很累人。能跟我说说具体是什么让你感到压力吗？",
      "created_at": "2025-11-25T10:31:08",
      "tool_calls": null
    }
  ],
  "has_more": true,
  "oldest_id": 95,
  "conversation_id": 1
}
```

### Pagination Flow

1. **Initial load**: Call without `before_id` to get the most recent messages.
2. **Load older**: Use `oldest_id` from response as `before_id` in next request.
3. **Stop when**: `has_more` is `false`.

```
Initial:  GET /chat/history/1?limit=50
          → messages[0..49], oldest_id=50, has_more=true

Page 2:   GET /chat/history/1?limit=50&before_id=50
          → messages[0..49], oldest_id=1, has_more=false
```

### Errors

| Status Code | Description |
| --- | --- |
| `500 Internal Server Error` | Database or unexpected failure. |

---

## 3. GET `/api/v1/chat/greeting/{user_id}`

Generate a personalized AI greeting when user opens the chat.

### Description

Returns a warm, contextual greeting based on:
- **Time of day** (早上好/下午好/晚上好)
- **Recent conversation history** (can reference last topic)
- **Pending follow-up events** (can mention things to check on)

Call this endpoint when the user opens the chat interface to display a personalized welcome message instead of an empty screen.

### Path Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| `user_id` | integer | User ID |

### Response — [`ChatGreetingResponse`](../app/schemas/chat.py)

| Field | Type | Description |
| --- | --- | --- |
| `greeting` | string | Personalized greeting message from the AI companion. |
| `has_pending_followups` | boolean | Whether there are pending follow-up events to discuss. |
| `is_returning_user` | boolean | Whether this user has chatted before. |

### Example Request

```bash
curl "http://localhost:8000/api/v1/chat/greeting/1"
```

### Example Responses

**New user (morning):**
```json
{
  "greeting": "早上好呀 ☀️ 今天有什么想聊的吗？",
  "has_pending_followups": false,
  "is_returning_user": false
}
```

**Returning user with recent conversation:**
```json
{
  "greeting": "下午好！上次聊到工作压力的事，现在好些了吗？",
  "has_pending_followups": true,
  "is_returning_user": true
}
```

**Returning user (evening):**
```json
{
  "greeting": "晚上好呀～今天过得怎么样？",
  "has_pending_followups": false,
  "is_returning_user": true
}
```

### Mobile App Integration

```
User opens chat screen
    ↓
App calls GET /chat/greeting/{user_id}
    ↓
Display greeting as first message (assistant bubble)
    ↓
Load chat history below greeting
    ↓
User can respond or scroll to see history
```

### Errors

| Status Code | Description |
| --- | --- |
| `404 Not Found` | User not found. |
| `500 Internal Server Error` | AI generation or database failure. |



## Appendix. Permission Request Flow Example
┌─────────────────────────────────────────────────────────────────┐
│                    PERMISSION REQUEST FLOW                       │
└─────────────────────────────────────────────────────────────────┘

User: "帮我设个明早7点的闹钟"
                    │
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│ Backend returns:                                                 │
│ {                                                                │
│   "reply": "好的，我来帮你设置明早7点的闹钟",                    │
│   "pending_client_actions": [{                                   │
│     "tool": "alarm_manager",                                     │
│     "action": "create_alarm",                                    │
│     "params": {"time": "07:00"}                                  │
│   }]                                                             │
│ }                                                                │
└─────────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│ iOS Client checks permission status:                             │
│                                                                  │
│ if permission_not_granted:                                       │
│   - Show system permission dialog                                │
│   - If denied: show explanation + settings link                  │
│ else:                                                            │
│   - Execute the action                                           │
│   - Report result back to chat (optional)                        │
└─────────────────────────────────────────────────────────────────┘
### Permission Groups:
Tool| iOS Permission	| When to Request
calendar_manager | EventKit (Calendar) | First calendar action
alarm_manager | None (uses Clock app URL scheme) | N/A
health_data | HealthKit | First health query
screen_time | Screen Time API | First screen time query

### Best Practices:

- Don't request all permissions upfront - Users are more likely to grant when they understand why
- Show context before requesting - "为了帮你查看日程，需要访问你的日历"
- Handle denial gracefully - AI can respond: "没关系，你也可以手动查看日历"
- Cache permission status - Don't repeatedly ask if already denied
