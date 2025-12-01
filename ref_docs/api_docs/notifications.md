# Notifications API

Push notification management for the AI Companion app.

## Overview

The notification system supports:
- Device token registration for iOS (APNs)
- User notification preferences with quiet hours
- Notification history and read status tracking
- Scheduled notifications

---

## Device Token Management

### Register Device Token

Register or update a device push token.

**Endpoint:** `POST /api/v1/notifications/device-token`

**Request Body:**
```json
{
  "user_id": 1,
  "device_id": "A1B2C3D4-E5F6-7890-ABCD-EF1234567890",
  "platform": "ios",
  "push_token": "abc123def456...",
  "push_provider": "apns",
  "app_version": "1.0.0",
  "os_version": "17.0",
  "device_model": "iPhone 15 Pro"
}
```

**Response:**
```json
{
  "id": 1,
  "user_id": 1,
  "device_id": "A1B2C3D4-E5F6-7890-ABCD-EF1234567890",
  "platform": "ios",
  "push_provider": "apns",
  "is_active": true,
  "created_at": "2025-11-30T10:00:00Z",
  "updated_at": "2025-11-30T10:00:00Z"
}
```

### Unregister Device Token

Unregister a device token (mark as inactive).

**Endpoint:** `DELETE /api/v1/notifications/device-token`

**Request Body:**
```json
{
  "user_id": 1,
  "device_id": "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
}
```

**Response:**
```json
{
  "success": true
}
```

---

## Notification Preferences

### Get Preferences

Get notification preferences for a user.

**Endpoint:** `GET /api/v1/notifications/preferences/{user_id}`

**Response:**
```json
{
  "user_id": 1,
  "enabled": true,
  "followup_enabled": true,
  "reminder_enabled": true,
  "goal_enabled": true,
  "system_enabled": true,
  "quiet_hours_enabled": true,
  "quiet_hours_start": "22:00",
  "quiet_hours_end": "08:00",
  "updated_at": "2025-11-30T10:00:00Z"
}
```

### Update Preferences

Update notification preferences for a user.

**Endpoint:** `PUT /api/v1/notifications/preferences/{user_id}`

**Request Body:** (only include fields to update)
```json
{
  "enabled": true,
  "followup_enabled": true,
  "reminder_enabled": true,
  "goal_enabled": true,
  "system_enabled": true,
  "quiet_hours_enabled": true,
  "quiet_hours_start": "22:00",
  "quiet_hours_end": "08:00"
}
```

**Response:** Same as GET preferences.

---

## Notification History

### List Notifications

Get notifications for a user with pagination.

**Endpoint:** `GET /api/v1/notifications/{user_id}`

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| limit | int | 20 | Max notifications (1-100) |
| offset | int | 0 | Pagination offset |
| status | string | null | Filter: pending, sent, failed, cancelled |
| notification_type | string | null | Filter: followup, reminder, goal, system |

**Response:**
```json
{
  "notifications": [
    {
      "id": 1,
      "user_id": 1,
      "title": "小宝提醒你",
      "body": "记得关心一下：朋友生日",
      "notification_type": "followup",
      "data": {"event_id": 123},
      "status": "sent",
      "scheduled_at": null,
      "sent_at": "2025-11-30T10:00:00Z",
      "read_at": null,
      "created_at": "2025-11-30T10:00:00Z"
    }
  ],
  "total": 1,
  "has_more": false
}
```

### Mark as Read

Mark a notification as read.

**Endpoint:** `POST /api/v1/notifications/{notification_id}/read`

**Request Body:**
```json
{
  "user_id": 1
}
```

**Response:**
```json
{
  "success": true,
  "read_at": "2025-11-30T10:05:00Z"
}
```

---

## Send Notification (Internal)

Send a notification to a user. For testing and internal use.

**Endpoint:** `POST /api/v1/notifications/send`

**Request Body:**
```json
{
  "user_id": 1,
  "title": "小宝提醒你",
  "body": "记得关心一下：朋友生日",
  "notification_type": "followup",
  "data": {"event_id": 123},
  "scheduled_at": "2025-12-01T09:00:00Z"
}
```

**Notification Types:**
| Type | Description |
|------|-------------|
| followup | Follow-up event reminders |
| reminder | General reminders |
| goal | Goal/task notifications |
| system | System notifications |

**Response:**
```json
{
  "id": 1,
  "user_id": 1,
  "title": "小宝提醒你",
  "body": "记得关心一下：朋友生日",
  "notification_type": "followup",
  "data": {"event_id": 123},
  "status": "pending",
  "scheduled_at": "2025-12-01T09:00:00Z",
  "sent_at": null,
  "read_at": null,
  "created_at": "2025-11-30T10:00:00Z"
}
```

---

## iOS Client Integration

### Getting APNs Token

```swift
// In AppDelegate or SceneDelegate
func application(_ application: UIApplication, 
                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    // Send token to backend
    registerDeviceToken(token: token)
}
```

### Registering Token with Backend

```swift
func registerDeviceToken(token: String) {
    let body: [String: Any] = [
        "user_id": currentUserId,
        "device_id": UIDevice.current.identifierForVendor?.uuidString ?? "",
        "platform": "ios",
        "push_token": token,
        "push_provider": "apns",
        "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
        "os_version": UIDevice.current.systemVersion,
        "device_model": UIDevice.current.model
    ]
    
    // POST to /api/v1/notifications/device-token
}
```

### Handling Notifications

```swift
// Handle notification when app is in foreground
func userNotificationCenter(_ center: UNUserNotificationCenter,
                           willPresent notification: UNNotification,
                           withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    // Show banner and play sound
    completionHandler([.banner, .sound])
}

// Handle notification tap
func userNotificationCenter(_ center: UNUserNotificationCenter,
                           didReceive response: UNNotificationResponse,
                           withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    // Navigate based on notification type
    if let type = userInfo["type"] as? String {
        switch type {
        case "followup_reminder":
            // Navigate to chat or followup detail
            break
        default:
            break
        }
    }
    completionHandler()
}
```

---

## Backend Configuration

### Environment Variables

```env
# APNs Configuration
APNS_KEY_ID=your_key_id           # From Apple Developer Portal
APNS_TEAM_ID=your_team_id         # Your Team ID
APNS_BUNDLE_ID=com.yourapp.bundle # App bundle identifier
APNS_KEY_PATH=path/to/AuthKey.p8  # Path to .p8 key file
APNS_USE_SANDBOX=true             # true for dev, false for production
```

### Scheduled Jobs

Process scheduled notifications (run every 5 minutes):
```bash
python -m scripts.run_scheduled_notifications
```

Process follow-up events with notifications (run every 12 hours):
```bash
python -m scripts.run_offline_followups --window-hours 12
```
