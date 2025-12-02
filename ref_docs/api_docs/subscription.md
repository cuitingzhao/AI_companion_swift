# Subscription API

订阅管理相关接口，支持14天免费试用和Apple In-App Purchase订阅。

> ⚠️ **认证要求**: 本模块所有接口都需要Bearer Token认证。请在请求头中添加：
> ```
> Authorization: Bearer <access_token>
> ```

## Base URL

```
/api/v1/subscription
```

---

## 概述

### 订阅状态流程

```
新用户注册 → 试用期(14天) → 试用过期 → 付费订阅/受限访问
                              ↓
                         Apple IAP购买
                              ↓
                         活跃订阅
```

### 订阅状态说明

| 状态 | 说明 | has_access |
|------|------|------------|
| trial | 试用期内 | ✅ true |
| active | 付费订阅有效 | ✅ true |
| expired | 试用/订阅已过期 | ❌ false |
| cancelled | 用户取消订阅 | ❌ false |

---

## 1. 获取订阅状态

获取当前用户的订阅状态信息。

### Endpoint

```
GET /api/v1/subscription/status
```

### Headers

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| Authorization | string | 是 | Bearer {access_token} |

### Response

**成功 (200)**

```json
{
  "has_access": true,
  "status": "trial",
  "plan_type": null,
  "trial_ends_at": "2024-12-16T10:30:00",
  "subscription_ends_at": null,
  "days_remaining": 12,
  "auto_renew_enabled": false
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| has_access | boolean | 是否有访问权限 |
| status | string | 订阅状态：trial/active/expired/cancelled |
| plan_type | string | null | 订阅计划：monthly/yearly（试用期为null） |
| trial_ends_at | string | null | 试用期结束时间（ISO 8601格式） |
| subscription_ends_at | string | null | 订阅结束时间（ISO 8601格式） |
| days_remaining | integer | null | 剩余天数 |
| auto_renew_enabled | boolean | 是否开启自动续订 |

**试用期响应示例**

```json
{
  "has_access": true,
  "status": "trial",
  "plan_type": null,
  "trial_ends_at": "2024-12-16T10:30:00",
  "subscription_ends_at": null,
  "days_remaining": 12,
  "auto_renew_enabled": false
}
```

**活跃订阅响应示例**

```json
{
  "has_access": true,
  "status": "active",
  "plan_type": "yearly",
  "trial_ends_at": "2024-12-02T10:30:00",
  "subscription_ends_at": "2025-12-02T10:30:00",
  "days_remaining": 365,
  "auto_renew_enabled": true
}
```

**过期响应示例**

```json
{
  "has_access": false,
  "status": "expired",
  "plan_type": null,
  "trial_ends_at": "2024-11-18T10:30:00",
  "subscription_ends_at": null,
  "days_remaining": null,
  "auto_renew_enabled": false
}
```

---

## 2. 验证Apple IAP收据

验证Apple In-App Purchase收据并激活订阅。

### Endpoint

```
POST /api/v1/subscription/verify-receipt
```

### Headers

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| Authorization | string | 是 | Bearer {access_token} |
| Content-Type | string | 是 | application/json |

### Request Body

```json
{
  "receipt_data": "MIIbngYJKoZIhvcNAQcCoIIbj..."
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| receipt_data | string | 是 | Base64编码的Apple收据数据 |

### Response

**成功 (200)**

```json
{
  "success": true,
  "message": null,
  "subscription": {
    "has_access": true,
    "status": "active",
    "plan_type": "monthly",
    "trial_ends_at": "2024-12-02T10:30:00",
    "subscription_ends_at": "2025-01-02T10:30:00",
    "days_remaining": 30,
    "auto_renew_enabled": true
  }
}
```

**失败 (200)**

```json
{
  "success": false,
  "message": "Receipt verification failed: The receipt could not be authenticated.",
  "subscription": null
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| success | boolean | 验证是否成功 |
| message | string | null | 错误消息（失败时） |
| subscription | object | null | 更新后的订阅状态（成功时） |

### 错误消息说明

| 消息 | 说明 |
|------|------|
| Apple IAP not configured | 服务器未配置APPLE_SHARED_SECRET |
| The receipt could not be authenticated | 收据无效或被篡改 |
| Subscription has expired | 收据中的订阅已过期 |
| No valid subscription found in receipt | 收据中没有有效的订阅信息 |

---

## 3. 恢复购买

恢复之前的Apple In-App Purchase购买记录。

### Endpoint

```
POST /api/v1/subscription/restore
```

### Headers

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| Authorization | string | 是 | Bearer {access_token} |
| Content-Type | string | 是 | application/json |

### Request Body

```json
{
  "receipt_data": "MIIbngYJKoZIhvcNAQcCoIIbj..."
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| receipt_data | string | 是 | Base64编码的Apple收据数据 |

### Response

**成功 (200)**

```json
{
  "success": true,
  "message": "Subscription restored successfully",
  "subscription": {
    "has_access": true,
    "status": "active",
    "plan_type": "yearly",
    "trial_ends_at": "2024-12-02T10:30:00",
    "subscription_ends_at": "2025-12-02T10:30:00",
    "days_remaining": 365,
    "auto_renew_enabled": true
  }
}
```

**无可恢复购买 (200)**

```json
{
  "success": false,
  "message": "No active subscription found to restore",
  "subscription": null
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| success | boolean | 恢复是否成功 |
| message | string | 状态消息 |
| subscription | object | null | 恢复后的订阅状态（成功时） |

---

## iOS客户端集成指南

### 1. 获取收据数据

```swift
// 获取App Store收据
guard let receiptURL = Bundle.main.appStoreReceiptURL,
      let receiptData = try? Data(contentsOf: receiptURL) else {
    return
}
let receiptString = receiptData.base64EncodedString()
```

### 2. 购买后验证

```swift
// 购买成功后调用
func verifyPurchase(receiptData: String) async {
    let url = URL(string: "\(baseURL)/api/v1/subscription/verify-receipt")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    
    let body = ["receipt_data": receiptData]
    request.httpBody = try? JSONEncoder().encode(body)
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let response = try JSONDecoder().decode(VerifyReceiptResponse.self, from: data)
    
    if response.success {
        // 订阅激活成功
    }
}
```

### 3. 恢复购买

```swift
// 用户点击"恢复购买"按钮时调用
func restorePurchases() async {
    // 先调用StoreKit恢复
    try? await AppStore.sync()
    
    // 然后发送收据到后端
    guard let receiptURL = Bundle.main.appStoreReceiptURL,
          let receiptData = try? Data(contentsOf: receiptURL) else {
        return
    }
    
    let url = URL(string: "\(baseURL)/api/v1/subscription/restore")!
    // ... 同上
}
```

---

## 付费墙（Paywall）处理

### 客户端检查订阅状态

```swift
func checkSubscription() async -> Bool {
    let url = URL(string: "\(baseURL)/api/v1/subscription/status")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let status = try JSONDecoder().decode(SubscriptionStatus.self, from: data)
    
    return status.hasAccess
}
```

### 服务端付费墙响应

当用户试用/订阅过期时，受保护的API会返回403错误：

```json
{
  "detail": {
    "code": "subscription_required",
    "message": "Your trial has expired. Please subscribe to continue.",
    "status": "expired"
  }
}
```

客户端收到此响应时应显示付费墙界面。

---

## 测试指南

### Sandbox测试

1. 在App Store Connect创建Sandbox测试账号
2. 在测试设备上登录Sandbox账号
3. 使用测试账号进行购买（不会实际扣款）
4. Sandbox订阅时间会加速（1个月 = 5分钟）

### 测试订阅状态

```bash
# 获取订阅状态
curl -X GET "https://your-api.com/api/v1/subscription/status" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## 注意事项

1. **试用期**：新用户注册时自动获得14天试用期
2. **收据验证**：每次购买/恢复都需要发送收据到后端验证
3. **自动续订**：由Apple处理，后端通过收据验证获取最新状态
4. **跨设备同步**：用户在新设备上需要调用"恢复购买"来同步订阅状态
