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
| `color` | string | Lucky colors for today based on Bazi theory (幸运色), up to 3 colors separated by comma. |
| `food` | string | Lucky food ingredients for today based on Bazi theory (幸运食材), up to 3 items separated by comma. |
| `direction` | string | Lucky directions for today based on Bazi theory (幸运方位), up to 2 characters per direction. |

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

---

## 2. GET `/api/v1/fortune/yearly`
Get a Bazi-based yearly fortune for **one specific life dimension**.

### Description
- Uses the user's stored Bazi chart and decennial cycles to compute a yearly fortune for a single dimension.
- The supported dimensions are defined by [`FortuneDimension`](../app/schemas/fortune.py):
  - `career`
  - `wealth`
  - `relationship`
  - `health`
- Each call only analyzes one dimension; other dimensions can be requested separately.
- **Unlock rule (MVP)** – enforced in the service using conversation history:
  - The user must have chatted on at least **3 distinct days**, and
  - The total number of messages (user + assistant) must be **> 50**.

### Query Parameters
| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `user_id` | integer | Yes | Existing user id from onboarding. |
| `dimension` | `FortuneDimension` | Yes | Life dimension to analyze: `career` \| `wealth` \| `relationship` \| `health`. |
| `year` | integer | No | Target Gregorian year. Defaults to the current year in the resolved timezone. |
| `tz` | string | No | Optional timezone identifier (e.g. `"Asia/Shanghai"`). If omitted, the backend default/user timezone is used. |

### Response — [`YearlyFortuneResponse`](../app/schemas/fortune.py)
| Field | Type | Description |
| --- | --- | --- |
| `context` | [`YearlyFortuneContext`](../app/schemas/fortune.py) | Context for this yearly fortune (target year and relevant decennial cycle). |
| `dimension` | `FortuneDimension` | Dimension this result describes. |
| `score` | integer (1–10) | Overall fortune score for this dimension in the target year (5 is neutral). |
| `trend` | string | One-sentence summary of the overall yearly trend. |
| `opportunities` | string | Key opportunities or favorable tendencies in this dimension. |
| `risks` | string | Key risks, challenges, or pressure points in this dimension. |
| `advice` | string | Practical, actionable advice grounded in Bazi reasoning for this dimension. |

#### `YearlyFortuneContext`
| Field | Type | Description |
| --- | --- | --- |
| `year` | integer | Target Gregorian year. |
| `current_decade` | string | Decennial luck cycle relevant for the target year, e.g. `"甲寅运"` or `"未起运（将于XXXX年起运）"`. |

### Errors
- `400 Bad Request` – invalid parameters or business-rule validation errors unrelated to unlock or missing data.
- `403 Forbidden` – yearly fortune is **locked** because unlock rules are not satisfied (not enough chat days or messages).
- `404 Not Found` – when the user or required Bazi chart/profile cannot be found.
- `500 Internal Server Error` – unexpected server failure.
