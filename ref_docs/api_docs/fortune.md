# Fortune API Documentation

Source file: [`app/api/v1/endpoints/fortune.py`](../app/api/v1/endpoints/fortune.py)

## 1. GET `/api/v1/fortune/daily`
Get today's Bazi-based daily fortune for a user.

### Description
- Uses the user's stored Bazi chart and the current date/time to compute a daily fortune.
- Requires that onboarding (including Bazi calculation) has been completed for the user.
- Returns structured context (solar/lunar date, Ganzhi pillars, current decade luck cycle) plus a summarized fortune assessment.

### Query Parameters
| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `user_id` | integer | Yes | Existing user id from onboarding. |
| `tz` | string | No | Optional timezone identifier (e.g. `"Asia/Shanghai"`). If omitted, the backend default timezone is used. |

### Response — [`DailyFortuneResponse`](../app/schemas/fortune.py)
| Field | Type | Description |
| --- | --- | --- |
| `context` | [`DailyFortuneContext`](../app/schemas/fortune.py) | Context for this daily fortune (dates, Ganzhi pillars, current decade). |
| `fortune_level` | enum (`"吉"`, `"平"`, `"凶"`) | Overall fortune classification for the day. |
| `good` | string | Description of favorable activities or tendencies today (typically starts with `"利："`). |
| `avoid` | string | Description of things to avoid today (typically starts with `"忌："`). |
| `reason` | string or null | Short Bazi-based explanation for today's fortune (optional). |

#### `DailyFortuneContext`
| Field | Type | Description |
| --- | --- | --- |
| `solar_date` | string | Current Gregorian date in `YYYY-MM-DD` format. |
| `lunar_date` | string | Current Chinese lunar date string. |
| `year_ganzhi` | [`Ganzhi`](../app/schemas/bazi.py) | Year pillar (年柱) for the current date. |
| `month_ganzhi` | [`Ganzhi`](../app/schemas/bazi.py) | Month pillar (月柱) for the current date. |
| `day_ganzhi` | [`Ganzhi`](../app/schemas/bazi.py) | Day pillar (日柱) for the current date. |
| `hour_ganzhi` | [`Ganzhi`](../app/schemas/bazi.py) | Hour pillar (时柱) for the current time. |
| `current_decade` | string | Current decennial luck cycle, e.g. `"甲寅运"` or `"未起运（将于XXXX年起运）"`. |

### Errors
- `400 Bad Request` – invalid parameters or business-rule validation errors (e.g. onboarding/Bazi not completed but not reported as "not found").
- `404 Not Found` – when the user or required Bazi chart cannot be found (mapped from `ValueError` messages like `"Bazi chart not found"`).
- `500 Internal Server Error` – unexpected server failure.
