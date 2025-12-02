# User API Documentation

Source file: [`app/api/v1/endpoints/user.py`](../app/api/v1/endpoints/user.py)

> ⚠️ **认证要求**: 本模块大部分接口需要Bearer Token认证。请在请求头中添加：
> ```
> Authorization: Bearer <access_token>
> ```

---

## 1. GET `/api/v1/users/today-plan`
Get or generate today's task plan for current user.

**🔒 需要认证**

### Description
- Returns the **daily task executions** for the user on the current date.
- If no `TaskExecution` records exist yet for today, the backend:
  - Uses `DailyTaskService.get_or_generate_daily_plan` to:
    - Load active goals for the user.
    - Select a **primary milestone** per goal based on priority + due_date.
    - Select all `pending` / `in_progress` tasks under the primary milestone (or no-milestone tasks if none).
    - Materialize them into `TaskExecution(status="planned")` rows for today.
- Subsequent calls on the same day simply return the existing executions.

> 注意：`user_id` 从认证Token中自动获取，无需在路径参数中传递。

### Response — [`DailyTaskPlanResponse`](../app/schemas/goal.py)
```json
{
  "date": "2025-11-19",
  "items": [
    {
      "execution_id": 1,
      "task_id": 123,
      "goal_id": 10,
      "milestone_id": 42,
      "goal_title": "三个月内雅思从 6 分到 7 分",
      "title": "晚上跑步 30 分钟",
      "estimated_minutes": 30,
      "priority": "high",
      "frequency": "daily",
      "status": "planned",
      "planned_date": "2025-11-19",
      "execution_date": null
    }
  ]
}
```

Field descriptions:

| Field | Type | Description |
| --- | --- | --- |
| `date` | string | The date of the plan in `YYYY-MM-DD` format. |
| `items` | array | List of daily task executions for this user on that date. |

Each item (`DailyTaskItemResponse`) has:

| Field | Type | Description |
| --- | --- | --- |
| `execution_id` | integer | ID of the `TaskExecution` row. |
| `task_id` | integer | Underlying task ID. |
| `goal_id` | integer | Goal ID this task belongs to. |
| `goal_title` | string \| null | Title of the goal this task belongs to, or `null` if not available. |
| `milestone_id` | integer \| null | Milestone ID, or `null` if task is not tied to a milestone. |
| `title` | string | Task title. |
| `estimated_minutes` | integer \| null | Estimated minutes to complete the task (if available). |
| `priority` | string | Task priority (`high`, `medium`, `low`). |
| `frequency` | string | Task frequency: `once`, `daily`, `weekly`, `weekdays`, `monthly`, `other`. |
| `status` | string | Execution status (`planned`, `completed`, `cancelled`, `postponed`, `auto_expired`, `failed`). |
| `planned_date` | string | Planned date for this execution (`YYYY-MM-DD`). |
| `execution_date` | string \| null | Actual date of completion/cancellation/postponement, or `null` if not yet acted upon. |

### Errors
- `500 Internal Server Error` – Unexpected failure while generating or loading the daily plan.

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
