# Calendar API Documentation

Source file: [`app/api/v1/endpoints/utils.py`](../app/api/v1/endpoints/utils.py)

## 1. GET `/api/v1/utils/calendar/today`
Return combined solar/lunar calendar information for the current moment, including:

- 当前公历日期和时间
- 当前农历日期（简要和完整描述）
- 当前时辰（地支 + 文本标签，如 "子时"）
- 当前节气名称（如果有）
- 下一节气名称及其公历日期和时间

### Query Parameters

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `tz` | string | No | Timezone name (IANA format), e.g., `"Asia/Shanghai"`. Default is `"Asia/Shanghai"`. |

### Response — [`CalendarInfoResponse`](../app/schemas/calendar.py)

```json
{
  "now": "2025-11-19T17:52:00+08:00",
  "solar_date": "2025-11-19",
  "lunar_date": "二〇二五年十月十八",
  "lunar_full": "二〇二五年十月十八 乙巳(蛇)年 ...",
  "shichen": {
    "earthly_branch": "酉",
    "label": "酉时"
  },
  "current_jieqi": "立冬",
  "next_jieqi": {
    "name": "小雪",
    "solar_datetime": "2025-11-22T11:59:00+08:00",
    "solar_date": "2025-11-22"
  }
}
```

Field descriptions:

| Field | Type | Description |
| --- | --- | --- |
| `now` | string | Current datetime in ISO 8601 format (includes timezone offset if available). |
| `solar_date` | string | Current Gregorian (solar) date in `YYYY-MM-DD` format. |
| `lunar_date` | string | Current Chinese lunar date (e.g., `"二〇二五年十月十八"`). |
| `lunar_full` | string | Full lunar date string with Ganzhi and zodiac details. |
| `shichen` | object | Current traditional Chinese time period (时辰) information. |
| `shichen.earthly_branch` | string | Earthly Branch of the current time (e.g., `"子"`, `"丑"`, `"寅"`). |
| `shichen.label` | string | Human-readable label for the period (e.g., `"子时"`). |
| `current_jieqi` | string \| null | Name of the current solar term (节气), or `null` if not within any term range. |
| `next_jieqi` | object \| null | Next solar term and its Gregorian datetime/date, or `null` if not available. |
| `next_jieqi.name` | string | Name of the next solar term. |
| `next_jieqi.solar_datetime` | string | ISO 8601 datetime when the next solar term occurs. |
| `next_jieqi.solar_date` | string | Gregorian date of the next solar term (`YYYY-MM-DD`). |

### Errors

- `400 Bad Request` – Invalid timezone name in `tz`.
- `500 Internal Server Error` – Unexpected failure while computing calendar information.
