# Profile API Documentation

Source file: [`app/api/v1/endpoints/profile.py`](../app/api/v1/endpoints/profile.py)

> ⚠️ **认证要求**: 本模块所有接口都需要Bearer Token认证。请在请求头中添加：
> ```
> Authorization: Bearer <access_token>
> ```

---

## 1. POST `/api/v1/profile/location`
Update the user's current city.

**🔒 需要认证**

### Description
- Invoked after the client obtains GPS permission or when the user manually edits their location.
- Persists `current_city` on the `Profile` model so that the KYC agent and future modules can reference it.
- Optional latitude/longitude can be logged for debugging but are not stored yet.

### Request Body — [`LocationUpdateRequest`](../app/schemas/profile.py)
| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `city` | string | Yes | Display name of the city (Chinese or English). |
| `latitude` | float (-90~90) | No | Optional GPS latitude. |
| `longitude` | float (-180~180) | No | Optional GPS longitude. |

> 注意：`user_id` 从认证Token中自动获取，无需在请求体中传递。

### Response — [`LocationUpdateResponse`](../app/schemas/profile.py)
```json
{
  "status": "success",
  "message": "Location updated successfully",
  "city": "北京"
}
```

### Errors
- `404 Not Found` – profile missing for the given `user_id`.
- `500 Internal Server Error` – unexpected failure while persisting.

### Example Flow
1. Client requests GPS access and receives coordinates.
2. Client reverse-geocodes coordinates to a city label.
3. Client calls this endpoint to store the city before KYC conversation begins.

---

## 2. GET `/api/v1/profile/location`
Retrieve the stored current city and birthplace for current user.

**🔒 需要认证**

> 注意：`user_id` 从认证Token中自动获取，无需在路径参数中传递。

### Response
```json
{
  "current_city": "北京",
  "birthplace": "上海"
}
```
- `current_city` can be `null` if not set yet.
- `birthplace` reflects the city selected during onboarding (read-only).

### Errors
- `404 Not Found` – profile missing for the provided `user_id`.
- `500 Internal Server Error` – general error retrieving data.
