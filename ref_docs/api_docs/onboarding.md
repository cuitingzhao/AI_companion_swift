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
