# Goal Onboarding API Documentation

Source file: [`app/api/v1/endpoints/goals.py`](../app/api/v1/endpoints/goals.py)

## 1. POST `/api/v1/goals/onboarding/message`
Send a user message to the goal-setting onboarding agent and receive the agent's reply plus stage information.

### Description
- Orchestrates a **multi-stage goal-setting workflow**:
  - `operator` → `goal_setting_expert` → `goal_splitting_expert` → `done` / `error`.
- Uses `GoalService.process_onboarding_message` to:
  - Build prompts with user context (nickname, age, personality summary, cities).
  - Call AI models through `ai_service` using a configurable model (`MODEL_GOAL_PLANNING`, fallback `deepseek-chat`).
  - Persist the resulting `Goal`, `Milestone`, `Task`, and `GoalSession` records.
- Designed to be used first during onboarding, and later reused from regular chat flows.

### Request Body — [`GoalOnboardingMessageRequest`](../app/schemas/goal.py)
| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `user_id` | integer | Yes | Existing user id created during onboarding. |
| `message` | string (1–2000 chars) | Yes | Raw user input from the goal onboarding chat. |

### Response — [`GoalOnboardingMessageResponse`](../app/schemas/goal.py)
| Field | Type | Description |
| --- | --- | --- |
| `reply` | string | Agent's message displayed to the user. |
| `stage` | string | Current stage of the workflow. Common values: `operator`, `goal_setting_expert`, `goal_splitting_expert`, `done`, `error`. |
| `goal_completed` | bool | Whether the goal onboarding flow has fully completed for this user. |
| `goal_id` | integer \| null | Persisted goal id, once a `Goal` has been created. |

### Errors
- `400 Bad Request` – AI returned invalid JSON or could not satisfy the expected contract.
- `500 Internal Server Error` – unexpected failures (`Internal server error: ...`).

### Sample Request
```bash
curl -X POST http://localhost:8000/api/v1/goals/onboarding/message \
  -H "Content-Type: application/json" \
  -d '{
        "user_id": 7,
        "message": "我想在三个月内减脂5公斤"
      }'
```

---

## 2. POST `/api/v1/goals/onboarding/skip`
Mark the goal-setting onboarding flow as skipped for the user.

### Description
- Uses `GoalService.skip_onboarding_goal` to mark the active `GoalSession` as:
  - `status = "completed"`, `stage = "done"`, `error_reason = "skipped_by_user"`.
- Does **not** delete any existing goals; it only closes the current onboarding goal session.
- Allows the user to continue using the app without finishing the guided goal-setting flow.

### Request Body — [`GoalOnboardingSkipRequest`](../app/schemas/goal.py)
| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `user_id` | integer | Yes | Target user id. |

### Response — [`GoalOnboardingSkipResponse`](../app/schemas/goal.py)
```json
{
  "status": "success",
  "message": "已跳过目标设定流程，你可以在之后的聊天中创建或调整目标。"
}
```

### Errors
- `500 Internal Server Error` – unexpected failures (`Internal server error: ...`).

---

## 3. GET `/api/v1/goals/onboarding/status/{user_id}`
Retrieve the goal-onboarding status and any persisted goal/milestone/task counts.

### Description
- Uses `GoalService.get_onboarding_goal_status` to inspect the current `GoalSession` (if any).
- Returns high-level progress indicators so the client can decide how to render the UI.
- If no active session exists, the response uses `stage = "none"` with zero counts.

### Path Parameters
| Name | Type | Description |
| --- | --- | --- |
| `user_id` | integer | Target user id. |

### Response — [`GoalOnboardingStatusResponse`](../app/schemas/goal.py)
```json
{
  "stage": "goal_splitting_expert",
  "goal_id": 12,
  "goal_summary": "三个月减脂5公斤",
  "milestones_count": 3,
  "tasks_count": 15
}
```

Field descriptions:

| Field | Type | Description |
| --- | --- | --- |
| `stage` | string | Current stage of the goal onboarding flow (`none`, `operator`, `goal_setting_expert`, `goal_splitting_expert`, `done`, `error`). |
| `goal_id` | integer \| null | Goal id associated with this session (if any). |
| `goal_summary` | string \| null | Short summary of the goal (typically the goal title). |
| `milestones_count` | integer | Number of `Milestone` records linked to the goal. |
| `tasks_count` | integer | Number of `Task` records linked to the goal. |

### Errors
- `500 Internal Server Error` – unexpected failures (`Internal server error: ...`).

---

## 4. GET `/api/v1/goals/{goal_id}/plan`
Retrieve the full goal plan, including metadata, milestones, and tasks, for a specific goal.

### Description
- Uses `GoalService.get_goal_plan` to load the `Goal` and its `Milestone` and `Task` records.
- Intended for clients to render the full plan after onboarding or in later goal management views.

### Path Parameters
| Name | Type | Description |
| --- | --- | --- |
| `goal_id` | integer | Target goal id. |

### Response — [`GoalPlanResponse`](../app/schemas/goal.py)
```json
{
  "goal_id": 12,
  "title": "三个月减脂5公斤",
  "desc": "在三个月内减脂5公斤，通过控制饮食和每周锻炼来实现。",
  "due_date": "2025-03-31",
  "daily_minutes": 60,
  "motivation": "改善健康、提升体型和精力状态。",
  "constraints": "工作日晚上时间有限，周末相对自由。",
  "progress": 20,
  "status": "active",
  "milestones": [
    {
      "id": 101,
      "title": "第一个月减脂 1.5 公斤",
      "desc": "通过控制饮食和规律运动，先实现初步的减脂目标。",
      "start_date": "2025-01-01",
      "due_date": "2025-01-31",
      "priority": "high",
      "status": "active",
      "tasks": [
        {
          "id": 1001,
          "title": "每周 3 次有氧运动（30 分钟）",
          "desc": null,
          "due_at": null,
          "estimated_minutes": 30,
          "frequency": "weekly",
          "status": "pending",
          "priority": "medium"
        }
      ]
    }
  ]
}
```

Field descriptions:

| Field | Type | Description |
| --- | --- | --- |
| `goal_id` | integer | Goal id. |
| `title` | string | Goal title. |
| `desc` | string \| null | Long-form description of the goal. |
| `due_date` | string \| null | Goal due date in ISO 8601 date format (`YYYY-MM-DD`). |
| `daily_minutes` | integer \| null | Recommended daily minutes to invest in this goal. |
| `motivation` | string \| null | Why the user wants this goal (from operator stage). |
| `constraints` | string \| null | Constraints and limitations relevant to the goal. |
| `progress` | integer | Current overall goal progress (0–100). |
| `status` | string | Goal status (e.g. `active`, `completed`, `paused`). |
| `milestones` | array | List of milestones with nested tasks. |

Milestone fields:

| Field | Type | Description |
| --- | --- | --- |
| `id` | integer | Milestone id. |
| `title` | string | Milestone title. |
| `desc` | string \| null | Milestone description / success criteria summary. |
| `start_date` | string \| null | Milestone start date in ISO 8601 date format (`YYYY-MM-DD`). |
| `due_date` | string \| null | Milestone due date in ISO 8601 date format (`YYYY-MM-DD`). |
| `priority` | string | Milestone priority (e.g. `high`, `medium`, `low`). |
| `status` | string | Milestone status (e.g. `active`, `completed`, `expired`). |
| `tasks` | array | List of tasks under this milestone. |

Task fields:

| Field | Type | Description |
| --- | --- | --- |
| `id` | integer | Task id. |
| `title` | string | Task title. |
| `desc` | string \| null | Task description (optional). |
| `due_at` | string \| null | Task due datetime in ISO 8601 format, if scheduled. |
| `estimated_minutes` | integer \| null | Estimated minutes required to complete this task. |
| `frequency` | string | Task frequency: `once`, `daily`, `weekly`, `weekdays`, `monthly`, or `other`. |
| `status` | string | Task status (e.g. `pending`, `in_progress`, `completed`, `expired`). |
| `priority` | string | Task priority (e.g. `high`, `medium`, `low`). |

### Errors
- `404 Not Found` – goal id does not exist.
- `500 Internal Server Error` – unexpected failures (`Internal server error: ...`).
