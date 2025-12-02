import Foundation

// MARK: - Request/Response Models

public struct ImageUploadRequest: Codable {
    public let imageData: String  // Base64-encoded image with data URI prefix
    
    public init(imageData: String) {
        self.imageData = imageData
    }
    
    enum CodingKeys: String, CodingKey {
        case imageData = "image_data"
    }
}

public struct ImageUploadResponse: Codable {
    public let url: String
    public let objectKey: String
    
    enum CodingKeys: String, CodingKey {
        case url
        case objectKey = "object_key"
    }
}

// MARK: - Media API

/// Media API - All endpoints require authentication
@MainActor
public final class MediaAPI {
    public static let shared = MediaAPI()
    private let client = APIClient.shared
    
    private init() {}
    
    /// POST /api/v1/media/upload/image
    /// Upload a single base64-encoded image to cloud storage.
    public func uploadImage(imageData: String) async throws -> ImageUploadResponse {
        let body = ImageUploadRequest(imageData: imageData)
        return try await client.post(path: "/api/v1/media/upload/image", body: body)
    }
    
    // MARK: - Deprecated (use methods without userId)
    
    @available(*, deprecated, message: "Use uploadImage(imageData:) instead - userId is now derived from token")
    public func uploadImage(userId: Int, imageData: String) async throws -> ImageUploadResponse {
        try await uploadImage(imageData: imageData)
    }
}
