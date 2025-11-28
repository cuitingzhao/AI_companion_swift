# Task Executions API Documentation

Source file: [`app/api/v1/endpoints/executions.py`](../app/api/v1/endpoints/executions.py)

## 1. PATCH `/api/v1/executions/{execution_id}`
Update a task execution status based on user action (complete / cancel / postpone).

### Description
- Operates on a single `TaskExecution` row representing a daily assignment of a `Task`.
- Supports three types of user actions:
  - `complete` – mark this execution as completed.
  - `cancel` – cancel this occurrence (task definition remains).
  - `postpone` – move this occurrence to a new date (non-daily tasks only).
- Also updates the underlying `Task` for one-off tasks when they are completed.

### Path Parameters
| Parameter | Type | Description |
| --- | --- | --- |
| `execution_id` | integer | ID of the `TaskExecution` to update. |

### Request Body — [`ExecutionUpdateRequest`](../app/schemas/goal.py)
| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `action` | string | Yes | One of: `"complete"`, `"cancel"`, `"postpone"`. |
| `new_date` | string (`YYYY-MM-DD`) | Required when `action="postpone"` | New planned date for the execution. Ignored otherwise. |
| `actual_minutes` | integer | No | Actual minutes spent on this execution (optional). |
| `note` | string | No | Optional note or comment from the user. |

### Behavior by Action

#### `action = "complete"`
- Sets `TaskExecution.status = "completed"`.
- Sets `TaskExecution.execution_date = today`.
- Sets `TaskExecution.source = "app_ui"`.
- Optionally stores `actual_minutes` and `note` if provided.
- If the underlying `Task.frequency = "once"` and `Task.status != "completed"`:
  - Sets `Task.status = "completed"`.
  - Sets `Task.completed_at = now`.

#### `action = "cancel"`
- Sets `TaskExecution.status = "cancelled"`.
- Sets `TaskExecution.execution_date = today`.
- Sets `TaskExecution.source = "app_ui"`.
- Optionally stores `actual_minutes` and `note`.
- Does **not** change the underlying `Task` definition.

#### `action = "postpone"`
- Only allowed when `Task.frequency` is **not** `"daily"` or `"weekdays"`.
- Requires `new_date` in `YYYY-MM-DD` format.
- Sets current `TaskExecution`:
  - `status = "postponed"`.
  - `execution_date = today`.
  - `source = "app_ui"`.
  - Optionally updates `note`.
- Creates a **new** `TaskExecution`:
  - Copies `user_id`, `goal_id`, `milestone_id`, `task_id` from the original.
  - Sets `planned_date = new_date`.
  - Sets `status = "planned"`, `source = "app_ui"`.

### Response — [`ExecutionUpdateResponse`](../app/schemas/goal.py)
| Field | Type | Description |
| --- | --- | --- |
| `status` | string | Always `"success"` on successful update. |
| `message` | string | Human-readable description of the result. |

### Example Requests

#### Mark execution as completed
```bash
curl -X PATCH "http://localhost:8000/api/v1/executions/123" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "complete",
    "actual_minutes": 25,
    "note": "今天状态不错，提前完成"
  }'
```

#### Cancel an execution
```bash
curl -X PATCH "http://localhost:8000/api/v1/executions/123" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "cancel",
    "note": "今天临时加班，做不了"
  }'
```

#### Postpone an execution to a new date
```bash
curl -X PATCH "http://localhost:8000/api/v1/executions/123" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "postpone",
    "new_date": "2025-11-21",
    "note": "今天有事，后天补做"
  }'
```

### Errors
- `400 Bad Request`
  - Invalid `action` (not one of `complete|cancel|postpone`).
  - `new_date` missing when `action="postpone"`.
  - `new_date` not in valid `YYYY-MM-DD` format.
  - Attempting to `postpone` a task with `frequency = "daily"` or `"weekdays"`.
- `404 Not Found`
  - `TaskExecution` with given `execution_id` does not exist.
  - Underlying `Task` for the execution does not exist.
- `500 Internal Server Error`
  - Unexpected server-side error while updating execution.

---

## 2. GET `/api/v1/executions/calendar/completion`
Get task completion summary for a date range, designed for calendar widgets.

### Description
- Returns daily task completion statistics for a user over a specified date range.
- Useful for calendar widgets that show different colors based on completion status.
- Only days with at least one planned task are included in the response.

### Query Parameters
| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `user_id` | integer | Yes | User ID. |
| `start_date` | string (`YYYY-MM-DD`) | No | Start of date range. Defaults to 30 days ago. |
| `end_date` | string (`YYYY-MM-DD`) | No | End of date range. Defaults to today. |

### Response — [`CalendarCompletionResponse`](../app/schemas/goal.py)
| Field | Type | Description |
| --- | --- | --- |
| `user_id` | integer | The user ID for this summary. |
| `start_date` | string | Start date of the range (`YYYY-MM-DD`). |
| `end_date` | string | End date of the range (`YYYY-MM-DD`). |
| `days` | array of `DailyCompletionItem` | List of daily completion summaries. |

#### `DailyCompletionItem`
| Field | Type | Description |
| --- | --- | --- |
| `date` | string | Date in `YYYY-MM-DD` format. |
| `total_tasks` | integer | Total number of tasks planned for this day. |
| `completed_tasks` | integer | Number of tasks completed on this day. |
| `completion_rate` | float (0.0 - 1.0) | Completion rate. `1.0` means all tasks completed. |

### Example Request
```bash
curl "http://localhost:8000/api/v1/executions/calendar/completion?user_id=1&start_date=2025-11-01&end_date=2025-11-30"
```

### Example Response
```json
{
  "user_id": 1,
  "start_date": "2025-11-01",
  "end_date": "2025-11-30",
  "days": [
    {
      "date": "2025-11-15",
      "total_tasks": 3,
      "completed_tasks": 3,
      "completion_rate": 1.0
    },
    {
      "date": "2025-11-16",
      "total_tasks": 2,
      "completed_tasks": 1,
      "completion_rate": 0.5
    },
    {
      "date": "2025-11-17",
      "total_tasks": 4,
      "completed_tasks": 0,
      "completion_rate": 0.0
    }
  ]
}
```

### Calendar Widget Color Mapping (Suggested)
| `completion_rate` | Suggested Color | Meaning |
| --- | --- | --- |
| `1.0` | Green | All tasks completed ✅ |
| `0.5 - 0.99` | Yellow/Orange | Partially completed |
| `0.01 - 0.49` | Light Red | Low completion |
| `0.0` | Red/Gray | No tasks completed |
| (no entry) | No color | No tasks planned for that day |

### Errors
- `400 Bad Request`
  - Invalid `start_date` or `end_date` format.
  - `start_date` is after `end_date`.
