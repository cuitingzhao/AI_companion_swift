# User API Documentation

Source file: [`app/api/v1/endpoints/user.py`](../app/api/v1/endpoints/user.py)

## 1. POST `/api/v1/users/guest`
Create a new guest user without requiring birth information or bazi analysis.

### Description
- Creates a guest user with minimal information for quick onboarding.
- Guest users can explore the app with limited functionality.
- Creates an empty profile associated with the guest user.
- Returns immediately (< 100ms) suitable for app startup.

### Request Body — [`CreateGuestUserRequest`](../app/schemas/user.py)
| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `nickname` | string | No | Optional nickname (1-100 characters). If not provided, generates default "访客{timestamp}". |
| `tz` | string | No | Timezone (default: "Asia/Shanghai"). |
| `locale` | string | No | Locale (default: "zh_CN"). |

### Response — [`CreateGuestUserResponse`](../app/schemas/user.py)
| Field | Type | Description |
| --- | --- | --- |
| `user_id` | integer | Created guest user ID. |
| `nickname` | string | Guest user nickname. |
| `is_guest` | boolean | Always `true` for guest users. |
| `created_at` | string (ISO datetime) | Creation timestamp. |

### Example Request
```json
{
  "nickname": "访客123",
  "tz": "Asia/Shanghai",
  "locale": "zh_CN"
}
```

### Example Response
```json
{
  "user_id": 1,
  "nickname": "访客123",
  "is_guest": true,
  "created_at": "2024-01-01T00:00:00"
}
```

### Errors
- `500 Internal Server Error` – Database or unexpected failure.

### Notes
- This is a quick operation designed for app startup.
- Guest users have `is_guest=true` flag in the database.
- Guest users can later be converted to formal users via the conversion endpoint.

---

## 2. POST `/api/v1/users/{user_id}/convert`
Convert a guest user to a formal user by providing birth information and performing complete onboarding.

### Description
- Verifies the user exists and is currently a guest user.
- Performs the same complete onboarding workflow as `/api/v1/onboarding/submit`.
- Calculates Bazi chart and performs AI personality analysis.
- Updates the existing user's `is_guest` flag to `false`.
- Updates the user's nickname.
- Links all analysis results to the existing user profile.

### Path Parameters
| Parameter | Type | Description |
| --- | --- | --- |
| `user_id` | integer | Guest user ID to convert. |

### Request Body — [`ConvertGuestUserRequest`](../app/schemas/user.py)
| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `nickname` | string | Yes | New nickname for formal user (1-100 characters). |
| `birth_time` | string (ISO datetime) | Yes | Birth datetime in local time (e.g., "1990-05-15T14:30:00"). |
| `city_id` | string | Yes | City ID from `/api/v1/utils/cities`. |
| `gender` | enum (`"male"`, `"female"`) | Yes | User gender for personality analysis. |

### Response — [`ConvertGuestUserResponse`](../app/schemas/user.py)
| Field | Type | Description |
| --- | --- | --- |
| `status` | string | "success" or "error". |
| `message` | string | Result description. |
| `user_id` | integer | Converted user ID. |
| `is_guest` | boolean | Should be `false` after successful conversion. |

### Example Request
```json
{
  "nickname": "小明",
  "birth_time": "1990-05-15T14:30:00",
  "city_id": "16",
  "gender": "male"
}
```

### Example Response
```json
{
  "status": "success",
  "message": "Guest user converted successfully",
  "user_id": 1,
  "is_guest": false
}
```

### Errors
- `400 Bad Request` – Invalid `city_id`, user is already a formal user, or validation errors.
- `404 Not Found` – User with specified ID does not exist.
- `500 Internal Server Error` – Database or AI processing failure.

### Notes
- Average latency: 10-30 seconds (same as full onboarding due to AI processing).
- After conversion, the user has full access to all app features.
- The conversion process creates `BaziChart` and `PersonalityAnalysis` records.
- To get the full analysis results, client should call `/api/v1/onboarding/submit` or implement a separate endpoint to fetch the analysis.

---

## User Flow Example

### Guest User Flow
1. **App Launch**: Client calls `POST /api/v1/users/guest` to create a guest user.
2. **Explore**: Guest user browses app with limited features.
3. **Upgrade Decision**: User decides to unlock full features.
4. **Conversion**: Client shows form to collect birth info, then calls `POST /api/v1/users/{user_id}/convert`.
5. **Full Access**: User now has complete bazi and personality analysis, unlocking all features.

### Direct Onboarding Flow (Existing)
1. **App Launch**: Client shows onboarding form immediately.
2. **Submit**: Client calls `POST /api/v1/onboarding/submit` with full info.
3. **Full Access**: User created as formal user from the start.
