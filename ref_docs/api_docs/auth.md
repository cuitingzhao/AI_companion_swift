# Authentication API

用户认证相关接口，支持手机号短信验证码登录/注册。

## Base URL

```
/api/v1/auth
```

---

## 1. 发送短信验证码

发送6位数字验证码到指定手机号。

### Endpoint

```
POST /api/v1/auth/sms/send
```

### Request Body

```json
{
  "phone": "13812345678"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| phone | string | 是 | 中国大陆手机号，11位数字，以1开头 |

### Response

**成功 (200)**

```json
{
  "success": true,
  "message": "验证码已发送",
  "retry_after": null
}
```

**频率限制 (200)**

```json
{
  "success": false,
  "message": "请 45 秒后重试",
  "retry_after": 45
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| success | boolean | 是否发送成功 |
| message | string | 状态消息 |
| retry_after | integer | null | 需要等待的秒数（频率限制时返回） |

### Rate Limits

| 限制类型 | 限制值 |
|----------|--------|
| 同一号码冷却时间 | 60秒 |
| 同一号码每小时 | 5次 |
| 同一号码每天 | 10次 |

---

## 2. 验证短信验证码并登录/注册

验证短信验证码，成功后返回认证令牌。

**行为取决于认证状态：**
- **无认证头**：如果手机号未注册，创建新账户；如果已注册，登录现有账户
- **有认证头（游客用户）**：将手机号绑定到当前用户，并转换为正式用户

### Endpoint

```
POST /api/v1/auth/sms/verify
```

### Headers (可选)

```
Authorization: Bearer <access_token>
```

如果携带游客用户的 token，会将手机号绑定到该用户。

### Request Body

```json
{
  "phone": "13812345678",
  "code": "123456",
  "device_info": "iPhone 15 Pro"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| phone | string | 是 | 手机号 |
| code | string | 是 | 6位验证码 |
| device_info | string | 否 | 设备信息，用于多设备管理 |

### Response

**成功 (200)**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...",
  "token_type": "Bearer",
  "expires_in": 900,
  "user": {
    "id": 123,
    "nickname": "用户5678",
    "avatar_url": null,
    "is_guest": false,
    "phone": "138****5678",
    "has_wechat": false
  },
  "is_new_user": true
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| access_token | string | JWT访问令牌，用于API认证 |
| refresh_token | string | 刷新令牌，用于获取新的访问令牌 |
| token_type | string | 令牌类型，固定为 "Bearer" |
| expires_in | integer | 访问令牌有效期（秒），默认900秒（15分钟） |
| user | object | 用户基本信息 |
| is_new_user | boolean | 是否为新注册用户 |

**验证失败 (400)**

```json
{
  "detail": "验证码错误，还剩 4 次机会"
}
```

### 验证码规则

- 验证码有效期：5分钟
- 最大尝试次数：5次
- 超过尝试次数需重新获取验证码

---

## 3. 刷新访问令牌

使用刷新令牌获取新的访问令牌和刷新令牌（令牌轮换）。

### Endpoint

```
POST /api/v1/auth/refresh
```

### Request Body

```json
{
  "refresh_token": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4..."
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| refresh_token | string | 是 | 当前的刷新令牌 |

### Response

**成功 (200)**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "bmV3IHJlZnJlc2ggdG9rZW4...",
  "token_type": "Bearer",
  "expires_in": 900
}
```

**失败 (401)**

```json
{
  "detail": "Invalid or expired refresh token"
}
```

### 注意事项

- 刷新令牌使用后会失效（令牌轮换）
- 刷新令牌有效期：30天
- 旧的刷新令牌不能再次使用

---

## 4. 登出

撤销刷新令牌，使其无法再用于获取新令牌。

### Endpoint

```
POST /api/v1/auth/logout
```

### Request Body

```json
{
  "refresh_token": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4..."
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| refresh_token | string | 是 | 要撤销的刷新令牌 |

### Response

**成功 (200)**

```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

### 注意事项

- 访问令牌在过期前仍然有效
- 如需立即失效所有令牌，需要在客户端清除存储的令牌

---

## 5. 获取当前用户信息

获取当前认证用户的详细信息。

### Endpoint

```
GET /api/v1/auth/me
```

### Headers

```
Authorization: Bearer <access_token>
```

### Response

**成功 (200)**

```json
{
  "id": 123,
  "nickname": "用户5678",
  "avatar_url": "https://example.com/avatar.jpg",
  "phone": "138****5678",
  "phone_verified": true,
  "has_wechat": false,
  "is_guest": false,
  "is_active": true,
  "has_completed_onboarding": true,
  "created_at": "2024-01-15T10:30:00Z",
  "last_login_at": "2024-03-20T14:25:00Z"
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| id | integer | 用户ID |
| nickname | string | 用户昵称 |
| avatar_url | string | null | 头像URL |
| phone | string | null | 脱敏手机号 |
| phone_verified | boolean | 手机号是否已验证 |
| has_wechat | boolean | 是否绑定微信 |
| is_guest | boolean | 是否为游客账户 |
| is_active | boolean | 账户是否激活 |
| has_completed_onboarding | boolean | 是否已完成八字分析 |
| created_at | datetime | 账户创建时间 |
| last_login_at | datetime | null | 最后登录时间 |

### 客户端路由逻辑

根据返回字段决定用户应该看到的页面：

| is_guest | has_completed_onboarding | 用户类型 | 客户端动作 |
|----------|--------------------------|----------|------------|
| false | true | 正式用户 | 进入首页 |
| true | true | 游客用户 | 显示登录/注册页 |
| false | false | 登录用户 | 跳转到 Onboarding（无登录选项） |
| - | - | 无 Token | 跳转到 Onboarding（有登录选项） |

**未认证 (401)**

```json
{
  "detail": "Not authenticated"
}
```

---

## 6. 删除账户

软删除当前用户账户。

### Endpoint

```
DELETE /api/v1/auth/me
```

### Headers

```
Authorization: Bearer <access_token>
```

### Request Body

```json
{
  "confirm": true,
  "reason": "不再使用此应用"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| confirm | boolean | 是 | 必须为 true 才能删除 |
| reason | string | 否 | 删除原因（可选） |

### Response

**成功 (200)**

```json
{
  "success": true,
  "message": "Account deleted successfully"
}
```

**未确认 (400)**

```json
{
  "detail": "Must confirm account deletion"
}
```

### 注意事项

- 这是软删除，账户数据会保留但标记为非活跃
- 删除后所有刷新令牌会被撤销
- 用户数据保留30天后可能被永久删除（根据数据保留策略）

---

## 认证方式

所有需要认证的接口都需要在请求头中携带访问令牌：

```
Authorization: Bearer <access_token>
```

### 令牌生命周期

| 令牌类型 | 有效期 | 用途 |
|----------|--------|------|
| Access Token | 15分钟 | API请求认证 |
| Refresh Token | 30天 | 获取新的访问令牌 |

### 错误响应

**401 Unauthorized**

```json
{
  "detail": "Not authenticated"
}
```

```json
{
  "detail": "Invalid or expired token"
}
```

---

## iOS 客户端集成指南

### 1. 完整用户流程

```swift
// ==========================================
// 流程 A: 新用户 - 先 Onboarding 后注册
// ==========================================

// 1. 完成 Onboarding（创建游客账户，获取 tokens）
let onboardingResponse = await api.post("/onboarding/submit", body: [
    "nickname": "小明",
    "birth_time": "1990-05-15T14:30:00",
    "city_id": "16",
    "gender": "male"
])
// 保存 tokens（此时 is_guest = true）
KeychainManager.save(accessToken: onboardingResponse.access_token)
KeychainManager.save(refreshToken: onboardingResponse.refresh_token)

// 2. 显示注册页面（用户可选择跳过）
// 如果用户选择注册：

// 3. 发送验证码
let smsResponse = await api.post("/auth/sms/send", body: ["phone": phoneNumber])

// 4. 验证并绑定手机号（携带现有 token）
// 注意：请求头中携带 Authorization: Bearer <access_token>
let authResponse = await api.post("/auth/sms/verify", body: [
    "phone": phoneNumber,
    "code": verificationCode,
    "device_info": UIDevice.current.name
])
// 更新 tokens（此时 is_guest = false）
KeychainManager.save(accessToken: authResponse.access_token)
KeychainManager.save(refreshToken: authResponse.refresh_token)

// ==========================================
// 流程 B: 老用户 - 直接登录
// ==========================================

// 1. 发送验证码
let response = await api.post("/auth/sms/send", body: ["phone": phoneNumber])

// 2. 验证并登录（无需 Authorization 头）
let authResponse = await api.post("/auth/sms/verify", body: [
    "phone": phoneNumber,
    "code": verificationCode,
    "device_info": UIDevice.current.name
])

// 3. 保存令牌
KeychainManager.save(accessToken: authResponse.access_token)
KeychainManager.save(refreshToken: authResponse.refresh_token)
```

### 2. 令牌刷新

```swift
// 在访问令牌过期前刷新
func refreshTokenIfNeeded() async {
    guard let refreshToken = KeychainManager.getRefreshToken() else { return }
    
    let response = await api.post("/auth/refresh", body: [
        "refresh_token": refreshToken
    ])
    
    if response.success {
        KeychainManager.save(accessToken: response.access_token)
        KeychainManager.save(refreshToken: response.refresh_token)
    } else {
        // 刷新失败，需要重新登录
        logout()
    }
}
```

### 3. 请求拦截器

```swift
// 自动添加认证头
class AuthInterceptor: RequestInterceptor {
    func intercept(request: URLRequest) -> URLRequest {
        var request = request
        if let token = KeychainManager.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}
```

---

## 数据模型

### UserBasicInfo

```json
{
  "id": "integer",
  "nickname": "string",
  "avatar_url": "string | null",
  "is_guest": "boolean",
  "phone": "string | null",
  "has_wechat": "boolean"
}
```

### AuthTokenResponse

```json
{
  "access_token": "string",
  "refresh_token": "string",
  "token_type": "string",
  "expires_in": "integer",
  "user": "UserBasicInfo",
  "is_new_user": "boolean"
}
```

### CurrentUserResponse

```json
{
  "id": "integer",
  "nickname": "string",
  "avatar_url": "string | null",
  "phone": "string | null",
  "phone_verified": "boolean",
  "has_wechat": "boolean",
  "is_guest": "boolean",
  "is_active": "boolean",
  "created_at": "datetime",
  "last_login_at": "datetime | null"
}
```
