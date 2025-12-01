# Media API Documentation

Source file: [`app/api/v1/endpoints/media.py`](../app/api/v1/endpoints/media.py)

## Overview

The Media API provides endpoints for uploading images to cloud storage (Alibaba Cloud OSS). Use these endpoints to upload images before sending them in chat messages.

---

## 1. POST `/api/v1/media/upload/image`

Upload a single base64-encoded image to cloud storage.

### Request Body — `ImageUploadRequest`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `user_id` | integer | Yes | User ID (must be > 0) |
| `image_data` | string | Yes | Base64-encoded image data. Can include data URI prefix (e.g., `data:image/png;base64,...`) or just the base64 string. |

### Response — `ImageUploadResponse`

| Field | Type | Description |
|-------|------|-------------|
| `url` | string | Public URL of the uploaded image |
| `object_key` | string | OSS object key (for internal reference) |

### Example Request

```bash
curl -X POST "http://localhost:8000/api/v1/media/upload/image" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "image_data": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
  }'
```

### Example Response

```json
{
  "url": "https://your-bucket.oss-cn-hangzhou.aliyuncs.com/chat-images/2025/12/1/abc123def456.png",
  "object_key": "chat-images/2025/12/1/abc123def456.png"
}
```

### Errors

| Status Code | Description |
|-------------|-------------|
| `400 Bad Request` | Invalid base64 data or unsupported image format |
| `503 Service Unavailable` | OSS is not configured |
| `500 Internal Server Error` | Upload failed |

---

## 2. POST `/api/v1/media/upload/images`

Upload multiple base64-encoded images to cloud storage.

### Request Body — `MultiImageUploadRequest`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `user_id` | integer | Yes | User ID (must be > 0) |
| `images` | array of string | Yes | List of base64-encoded images (max 4) |

### Response — `MultiImageUploadResponse`

| Field | Type | Description |
|-------|------|-------------|
| `urls` | array of string | List of public URLs for uploaded images (same order as input) |

### Example Request

```bash
curl -X POST "http://localhost:8000/api/v1/media/upload/images" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "images": [
      "data:image/png;base64,iVBORw0KGgo...",
      "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
    ]
  }'
```

### Example Response

```json
{
  "urls": [
    "https://your-bucket.oss-cn-hangzhou.aliyuncs.com/chat-images/2025/12/1/abc123.png",
    "https://your-bucket.oss-cn-hangzhou.aliyuncs.com/chat-images/2025/12/1/def456.jpg"
  ]
}
```

---

## Supported Image Formats

- PNG
- JPEG/JPG
- GIF
- WebP
- HEIC

---

## iOS Client Integration

### Workflow for Sending Images in Chat

1. **User selects/takes photo** in the app
2. **Convert to base64** (with data URI prefix recommended)
3. **Upload to OSS** via `POST /api/v1/media/upload/image`
4. **Get permanent URL** from response
5. **Send chat message** with the URL in the `images` array

```swift
// Example iOS flow
func sendImageMessage(image: UIImage, message: String) async throws {
    // 1. Convert to base64
    let imageData = image.jpegData(compressionQuality: 0.8)!
    let base64 = "data:image/jpeg;base64," + imageData.base64EncodedString()
    
    // 2. Upload to OSS
    let uploadResponse = try await api.uploadImage(userId: userId, imageData: base64)
    
    // 3. Send chat message with URL
    let chatResponse = try await api.sendMessage(
        userId: userId,
        message: message,
        images: [uploadResponse.url]
    )
}
```

---

## Configuration

The following environment variables must be set for image upload to work:

```env
ALIYUN_ACCESS_KEY_ID=your_access_key_id
ALIYUN_ACCESS_KEY_SECRET=your_access_key_secret
ALIYUN_OSS_ENDPOINT=oss-cn-hangzhou.aliyuncs.com
ALIYUN_OSS_BUCKET=your_bucket_name
ALIYUN_OSS_CUSTOM_DOMAIN=cdn.yourdomain.com  # Optional
```

If OSS is not configured, the upload endpoints will return `503 Service Unavailable`.

---

## Storage Organization

Images are stored in OSS with the following path structure:

```
chat-images/{year}/{month}/{user_id}/{uuid}.{ext}
```

Example: `chat-images/2025/12/1/abc123def456.png`

This organization:
- Groups images by date for easy management
- Separates images by user for privacy
- Uses UUID to prevent filename conflicts
