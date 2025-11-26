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
5. **Returns response** with reply, follow-up events, and tool execution records

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
| `events` | array of `ChatEventPayload` | Follow-up memory events (create/update instructions). |
| `tool_calls_made` | array of `ToolCallRecord` | Tools called during this chat turn. Empty if no tools invoked. |
| `pending_client_actions` | array of `PendingClientAction` | Actions for iOS client to execute locally (calendar, alarm, etc.). |

#### `ChatEventPayload` Structure

| Field | Type | Description |
| --- | --- | --- |
| `event_id` | integer \| null | Existing event ID for updates; null/omitted for new events. |
| `desc` | string | Natural-language description of the event. |
| `is_event_new` | boolean | `true` for new events, `false` for updates. |
| `progress_note` | string \| null | Progress note for this event update. |
| `priority` | string | Priority level: `"low"`, `"medium"`, or `"high"`. |
| `event_state` | string | Event state: `"active"` or `"resolved"`. |

#### `ToolCallRecord` Structure

| Field | Type | Description |
| --- | --- | --- |
| `tool` | string | Name of the tool that was called. |
| `arguments` | object | Arguments passed to the tool. |
| `result` | object | Result returned by the tool execution. |

#### `PendingClientAction` Structure

| Field | Type | Description |
| --- | --- | --- |
| `tool` | string | Name of the iOS native tool (e.g., `calendar_manager`, `alarm_manager`). |
| `action` | string | Action to perform (e.g., `create_event`, `create_alarm`). |
| `params` | object | Parameters for the action. |

### Available Tools

When `enable_tools=true`, the AI can call these tools:

| Tool Name | Description | Use Case | Execution |
| --- | --- | --- | --- |
| `ganzhi_calculator` | 计算指定日期的天干地支信息 | 用户询问运势、流年流月时 | Backend |
| `goal_manager` | 管理用户的目标、里程碑和任务 | 用户查询或更新目标进度时 | Backend |
| `web_search` | 搜索互联网获取最新信息 | 用户询问新闻、实时信息时 | Backend (Tavily API) |
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
  "events": [],
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

### Example Response (with follow-up event)

```json
{
  "reply": "听起来你最近工作压力挺大的，要注意休息哦。我会记住这件事，过几天再问问你情况怎么样了。",
  "events": [
    {
      "event_id": null,
      "desc": "用户工作压力大，需要关心",
      "is_event_new": true,
      "progress_note": null,
      "priority": "medium",
      "event_state": "active"
    }
  ],
  "tool_calls_made": [],
  "pending_client_actions": []
}
```

### Example Response (with iOS native tool)

```json
{
  "reply": "好的，我来帮你设置明早7点的闹钟。",
  "events": [],
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

### Example Response (no tools, no events)

```json
{
  "reply": "哈哈，今天心情不错嘛！有什么开心的事情想分享吗？😊",
  "events": [],
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

1. **Tool Execution Loop**: When AI decides to use a tool, the system automatically executes it and feeds the result back to the AI. This may happen multiple times (up to 5 rounds) before a final response.

2. **Follow-up Memory**: The AI can create or update follow-up events to remember things to check on later. At most one event is processed per turn.

3. **Context Building**: The system automatically includes:
   - User profile (nickname, age, gender, personality)
   - Bazi chart information (if available)
   - Active follow-up events due for today
   - **Recent conversation history** (last 10 messages for continuity)

4. **Model Selection**: Default model is `deepseek-chat`. Override via `model_name` in request or `MODEL_MAIN_CHAT` environment variable.

5. **Message Persistence**: All user and assistant messages are automatically saved to the conversation history.

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


## 4. Permission Request Flow Example
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
