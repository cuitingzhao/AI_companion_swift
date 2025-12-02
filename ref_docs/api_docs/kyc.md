# KYC Agent API Documentation

Source file: [`app/api/v1/endpoints/kyc.py`](../app/api/v1/endpoints/kyc.py)

> ⚠️ **认证要求**: 本模块所有接口都需要Bearer Token认证。请在请求头中添加：
> ```
> Authorization: Bearer <access_token>
> ```

---

## 1. POST `/api/v1/kyc/message`
Send a user message to the KYC agent and receive the agent's reply plus collection status.

**🔒 需要认证**

### Description
- Orchestrates staged KYC data collection (student/work status, relationship, multi-hobby gathering).
- Builds a dynamic prompt via `KYCService` -> `build_kyc_prompt`, then calls AI (DeepSeek).
- Updates `Profile` records with collected fields and marks completion when all requirements are met.

### Request Body — [`KYCMessageRequest`](../app/schemas/kyc.py)
| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `message` | string (1-1000 chars) | Yes | Raw user input from the chat UI. |

> 注意：`user_id` 从认证Token中自动获取，无需在请求体中传递。

### Response — [`KYCMessageResponse`](../app/schemas/kyc.py)
| Field | Type | Description |
| --- | --- | --- |
| `reply` | string | Agent's message displayed to the user. |
| `collection_status` | enum (`"进行中"`, `"完成"`) | Agent-reported progress for the dialogue turn. |
| `kyc_completed` | bool | Consolidated server-side completion check. |

### Errors
- `404 Not Found` – profile missing or KYC prerequisites not met.
- `500 Internal Server Error` – AI call or persistence failure.

### Sample Request
```bash
curl -X POST http://localhost:8000/api/v1/kyc/message \
  -H "Content-Type: application/json" \
  -d '{
        "user_id": 7,
        "message": "我是学生"
      }'
```

---

## 2. POST `/api/v1/kyc/skip`
Mark the KYC flow as skipped for the user.

### Description
- Sets `profile.kyc_completed = True` without collecting data.
- Allows the user to proceed while keeping fields empty for future collection.

### Request Body — [`KYCSkipRequest`](../app/schemas/kyc.py)
| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `user_id` | integer | Yes | Profile must exist. |

### Response — [`KYCSkipResponse`](../app/schemas/kyc.py)
```json
{
  "status": "success",
  "message": "已跳过KYC信息收集，你可以随时在聊天中补充这些信息"
}
```

### Errors
- `404 Not Found` – profile missing.
- `500 Internal Server Error` – unexpected failure.

---

## 3. GET `/api/v1/kyc/status/{user_id}`
Retrieve KYC completion status and field coverage.

### Description
- Returns what has been collected so far vs. remaining.
- Useful for orchestrating UI flows (e.g., resume partially completed KYC).

### Path Parameters
| Name | Type | Description |
| --- | --- | --- |
| `user_id` | integer | Target user id. |

### Response — [`KYCStatusResponse`](../app/schemas/kyc.py)
```json
{
  "kyc_completed": false,
  "collected_fields": {
    "is_student": "是",
    "relationship_status": "单身",
    "hobbies": ["打篮球", "看电影"]
  },
  "pending_fields": ["work_status"]
}
```

### Errors
- `404 Not Found` – profile missing.
- `500 Internal Server Error` – failure querying data.
