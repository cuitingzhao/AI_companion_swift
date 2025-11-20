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
