# Onboarding API Documentation

Source file: [`app/api/v1/endpoints/onboarding.py`](../app/api/v1/endpoints/onboarding.py)

> ⚠️ **认证要求**: 除 `/submit` 外，本模块其他接口都需要Bearer Token认证。请在请求头中添加：
> ```
> Authorization: Bearer <access_token>
> ```

---

## 1. POST `/api/v1/onboarding/submit`
Submit onboarding details and trigger the full astrology/personality workflow.

**🔓 无需认证** - 此接口创建新用户并返回Token

### Description
- Validates input, enriches with location metadata, creates `User` + `Profile` records.
- Calculates true solar time, Bazi chart, and AI-driven astrology analysis.
- Calls AI to produce personality traits and stores them in `PersonalityAnalysis`.
- Returns the user id plus the analysis results required on the client.

### Request Body — [`OnboardingSubmitRequest`](../app/schemas/onboarding.py)
| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `nickname` | string | Yes | 1-100 characters. |
| `birth_time` | string (ISO datetime) | Yes | Example: `"1990-05-15T14:30:00"` (local time). |
| `city_id` | string | Yes | Must exist in `/api/v1/utils/cities`. |
| `gender` | enum (`"male"`, `"female"`) | Yes | Used for personality prompt context. |

### Response — [`OnboardingSubmitResponse`](../app/schemas/onboarding.py)
| Field | Type | Description |
| --- | --- | --- |
| `user_id` | integer | Newly created user id. |
| `bazi_analysis` | [`BaziAnalysisResult`](../app/schemas/onboarding.py) | Body strength, useful gods, etc. |
| `personality_traits` | array of [`PersonalityTrait`](../app/schemas/onboarding.py) | Trait text plus stable `id` values (0-indexed) for later feedback. |
| `access_token` | string | JWT access token for API authentication. |
| `refresh_token` | string | Refresh token for obtaining new access tokens. |
| `expires_in` | integer | Access token expiry in seconds (default 900). |

**Note:** The user created via this endpoint is a **guest user** (`is_guest=true`). To convert to a registered user, the client should call `/api/v1/auth/sms/verify` with the access token to bind a phone number.

### Errors
- `400 Bad Request` – invalid `city_id`, missing fields, etc.
- `500 Internal Server Error` – unexpected failure (`Onboarding processing failed: ...`).

### Notes
- Average latency 10-30s because two AI calls (Bazi & personality).
- Client should cache `user_id` & `personality_traits` for the feedback step.

---

## 2. POST `/api/v1/onboarding/feedback`
Submit per-trait personality feedback after the user reviews each AI-generated trait.

**🔒 需要认证**

### Description
- Validates that the user has an active `PersonalityAnalysis` and trait ids remain in range.
- Saves enriched feedback (trait id, original trait text, flag, optional comment) into `trait_feedbacks` JSON column.
- Marks onboarding feedback as completed.

### Request Body — [`OnboardingFeedbackRequest`](../app/schemas/onboarding.py)
| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `trait_feedbacks` | array of [`TraitFeedback`](../app/schemas/onboarding.py) | Yes | Provide feedback for each reviewed trait. |

> 注意：`user_id` 从认证Token中自动获取，无需在请求体中传递。

`TraitFeedback` structure:
| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `trait_id` | integer ≥ 0 | Yes | Index received in `personality_traits`. |
| `feedback_flag` | enum (`accurate`, `not_accurate`, `somewhat_accurate`) | Yes | Accuracy assessment. |
| `comment` | string ≤ 200 | No | Optional free-text comment for this trait. |

### Response — [`OnboardingFeedbackResponse`](../app/schemas/onboarding.py)
```json
{
  "status": "success",
  "message": "Feedback saved successfully. Onboarding completed!"
}
```

### Errors
- `404 Not Found` – if profile/personality analysis cannot be located for the `user_id`.
- `500 Internal Server Error` – for persistence/validation issues (logged for debugging).

---

## 3. POST `/api/v1/onboarding/message`
Conversational KYC step during onboarding.

**🔒 需要认证**

### Description
- Handles a single turn of the KYC conversation.
- The AI asks follow-up questions, comments on the user’s answers, and tracks which KYC fields are completed.
- For student users, work-related fields can be automatically marked as "不适用".

### Request Body — [`KYCMessageRequest`](../app/schemas/kyc.py)
| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `message` | string (1–1000 chars) | Yes | User's current free-text reply in the KYC conversation. |
| `history` | array of objects | No | Optional chat history maintained by the client, each item has `role` (`"user"` or `"assistant"`) and `content` (string). |

> 注意：`user_id` 从认证Token中自动获取，无需在请求体中传递。

Example:

```json
{
  "message": "我是学生",
  "history": [
    { "role": "assistant", "content": "嗨，Popo，我是你的AI陪伴助手Popo宝，方便先告诉我你现在所在的城市吗？" },
    { "role": "user", "content": "我在上海" }
  ]
}
```

### Response — [`KYCMessageResponse`](../app/schemas/kyc.py)
| Field | Type | Description |
| --- | --- | --- |
| `reply` | string | AI reply to show to the user for the next turn. |
| `collection_status` | string | Either `"进行中"` or `"完成"`. |
| `kyc_completed` | boolean | Whether all required KYC info has been collected. |

### Errors
- `404 Not Found` – if the `user_id` cannot be resolved.
- `500 Internal Server Error` – unexpected failures (`Internal server error: ...`).

---

## 6. POST `/api/v1/onboarding/message/location`
**目前这个接口没有使用，因为如果相差太远的话可能会有误导性**
Location-based KYC message to inform the AI of the user's current city using GPS coordinates.

**🔒 需要认证**

### Description
- Accepts device GPS coordinates (`latitude`, `longitude`).
- Uses backend city data (`cities.json`) to find the nearest city.
- Sends a synthesized first-person message like `"我所在的城市为喀什地区（新疆）。"` into the KYC conversation.
- Returns the usual KYC conversation response so the client can display the AI's reply.

### Request Body — [`KYCLocationMessageRequest`](../app/schemas/kyc.py)
| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `latitude` | float | Yes | GPS latitude from the client. |
| `longitude` | float | Yes | GPS longitude from the client. |

> 注意：`user_id` 从认证Token中自动获取，无需在请求体中传递。

### Response — [`KYCMessageResponse`](../app/schemas/kyc.py)
Same structure as `/api/v1/onboarding/message`:

| Field | Type | Description |
| --- | --- | --- |
| `reply` | string | AI reply after receiving the synthesized city message. |
| `collection_status` | string | Either `"进行中"` or `"完成"`. |
| `kyc_completed` | boolean | Whether all required KYC info has been collected. |

### Example

```bash
curl -X POST "http://localhost:8000/api/v1/onboarding/message/location" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <access_token>" \
  -d '{
    "latitude": 37.785834,
    "longitude": -122.406417
  }'
```

### Errors
- `404 Not Found` – if the `user_id` cannot be resolved or no city can be determined from the coordinates.
- `500 Internal Server Error` – unexpected failures (`Internal server error: ...`).
---

## 4. POST `/api/v1/onboarding/skip`
Skip the KYC conversation during onboarding.

**🔒 需要认证**

### Description
- Marks KYC as skipped so the user can continue using the app without completing all KYC questions.
- The missing information can be collected later in normal conversations.

> 注意：`user_id` 从认证Token中自动获取，无需在请求体中传递。

### Response — [`KYCSkipResponse`](../app/schemas/kyc.py)
```json
{
  "status": "success",
  "message": "已跳过KYC信息收集，你可以随时在聊天中补充这些信息"
}
```

### Errors
- `404 Not Found` – if the `user_id` cannot be resolved.
- `500 Internal Server Error` – unexpected failures (`Internal server error: ...`).

---

## 5. GET `/api/v1/onboarding/status`
Check the KYC collection status for current user.

**🔒 需要认证**

### Description
- Returns which KYC fields have already been collected and which are still pending.
- Allows the client to decide whether to continue the KYC conversation or show a “completed” state.

> 注意：`user_id` 从认证Token中自动获取，无需在路径参数中传递。

### Response — [`KYCStatusResponse`](../app/schemas/kyc.py)
| Field | Type | Description |
| --- | --- | --- |
| `kyc_completed` | boolean | Whether KYC is fully completed for the user. |
| `collected_fields` | object | Map of field name → collected value. |
| `pending_fields` | array of strings | KYC field names still to be collected. |

### Errors
- `404 Not Found` – if the `user_id` cannot be resolved.
- `500 Internal Server Error` – unexpected failures (`Internal server error: ...`).
