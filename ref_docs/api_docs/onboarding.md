# Onboarding API Documentation

Source file: [`app/api/v1/endpoints/onboarding.py`](../app/api/v1/endpoints/onboarding.py)

## 1. POST `/api/v1/onboarding/submit`
Submit onboarding details and trigger the full astrology/personality workflow.

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

### Errors
- `400 Bad Request` – invalid `city_id`, missing fields, etc.
- `500 Internal Server Error` – unexpected failure (`Onboarding processing failed: ...`).

### Notes
- Average latency 10-30s because two AI calls (Bazi & personality).
- Client should cache `user_id` & `personality_traits` for the feedback step.

---

## 2. POST `/api/v1/onboarding/feedback`
Submit per-trait personality feedback after the user reviews each AI-generated trait.

### Description
- Validates that the user has an active `PersonalityAnalysis` and trait ids remain in range.
- Saves enriched feedback (trait id, original trait text, flag, optional comment) into `trait_feedbacks` JSON column.
- Marks onboarding feedback as completed.

### Request Body — [`OnboardingFeedbackRequest`](../app/schemas/onboarding.py)
| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `user_id` | integer | Yes | Returned from `/onboarding/submit`. |
| `trait_feedbacks` | array of [`TraitFeedback`](../app/schemas/onboarding.py) | Yes | Provide feedback for each reviewed trait. |

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

### Description
- Handles a single turn of the KYC conversation.
- The AI asks follow-up questions, comments on the user’s answers, and tracks which KYC fields are completed.
- For student users, work-related fields can be automatically marked as "不适用".

### Request Body — [`KYCMessageRequest`](../app/schemas/kyc.py)
| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `user_id` | integer | Yes | Existing user id from `/onboarding/submit`. |
| `message` | string (1–1000 chars) | Yes | User’s free-text reply in the KYC conversation. |

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

## 4. POST `/api/v1/onboarding/skip`
Skip the KYC conversation during onboarding.

### Description
- Marks KYC as skipped so the user can continue using the app without completing all KYC questions.
- The missing information can be collected later in normal conversations.

### Request Body — [`KYCSkipRequest`](../app/schemas/kyc.py)
| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `user_id` | integer | Yes | Existing user id from `/onboarding/submit`. |

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

## 5. GET `/api/v1/onboarding/status/{user_id}`
Check the KYC collection status for a given user.

### Description
- Returns which KYC fields have already been collected and which are still pending.
- Allows the client to decide whether to continue the KYC conversation or show a “completed” state.

### Path Parameters
| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `user_id` | integer | Yes | Existing user id from `/onboarding/submit`. |

### Response — [`KYCStatusResponse`](../app/schemas/kyc.py)
| Field | Type | Description |
| --- | --- | --- |
| `kyc_completed` | boolean | Whether KYC is fully completed for the user. |
| `collected_fields` | object | Map of field name → collected value. |
| `pending_fields` | array of strings | KYC field names still to be collected. |

### Errors
- `404 Not Found` – if the `user_id` cannot be resolved.
- `500 Internal Server Error` – unexpected failures (`Internal server error: ...`).
