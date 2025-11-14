# Cities API Documentation

## 1. GET `/api/v1/utils/cities`
Retrieve a list of cities with optional search and filtering.

### Description
- Provides city metadata sourced from `app/utils/city_utils.py` and served via `@router.get("/cities")` in `app/api/v1/endpoints/utils.py`.
- Results include latitude/longitude for downstream features such as true solar time conversion during onboarding.

### Query Parameters
| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `q` | string | No | Case-insensitive match against the city name (Chinese) or ASCII/Pinyin. |
| `province` | string | No | Exact match on the province/admin region (e.g., `"北京"`, `"广东"`). |
| `limit` | integer (1-1000) | No | Maximum number of results. When omitted the full filtered list is returned. |

### Response Schema
- `200 OK` → [`CityListResponse`](../app/schemas/city.py) containing:
  - `cities`: array of [`City`](../app/schemas/city.py) objects
  - `total`: integer count of returned cities
- `500 Internal Server Error` → `{ "detail": "Failed to load cities: <reason>" }`

### Usage Example
```bash
curl "http://localhost:8000/api/v1/utils/cities?q=shanghai&limit=5"
```

```json
{
  "cities": [
    {
      "id": "310000",
      "name": "上海",
      "ascii": "Shanghai",
      "country": "China",
      "admin": "上海",
      "lat": 31.2286,
      "lng": 121.4747
    }
  ],
  "total": 1
}
```

## 2. GET `/api/v1/utils/cities/{city_id}`
Fetch detailed information for a specific city.

### Path Parameters
| Name | Type | Description |
| --- | --- | --- |
| `city_id` | string | Unique identifier from the cities dataset. |

### Responses
- `200 OK` → [`City`](../app/schemas/city.py)
- `404 Not Found` → `{ "detail": "City not found: {city_id}" }`
- `500 Internal Server Error` → `{ "detail": "Failed to load cities: <reason>" }`

### Usage Example
```bash
curl "http://localhost:8000/api/v1/utils/cities/310000"
```
