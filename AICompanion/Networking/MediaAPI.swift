import Foundation

// MARK: - Request/Response Models

public struct ImageUploadRequest: Codable {
    public let userId: Int
    public let imageData: String  // Base64-encoded image with data URI prefix
    
    public init(userId: Int, imageData: String) {
        self.userId = userId
        self.imageData = imageData
    }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
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

public enum MediaAPIError: Error {
    case invalidURL
    case badResponse
    case decodingError
    case uploadFailed(String)
}

@MainActor
public final class MediaAPI {
    public static let shared = MediaAPI()
    public let baseURL: URL
    
    public init(baseURL: URL = URL(string: "http://localhost:8000")!) {
        self.baseURL = baseURL
    }
    
    /// POST /api/v1/media/upload/image
    /// Upload a single base64-encoded image to cloud storage.
    public func uploadImage(userId: Int, imageData: String) async throws -> ImageUploadResponse {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/media/upload/image"
        
        guard let url = components.url else {
            throw MediaAPIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let request = ImageUploadRequest(userId: userId, imageData: imageData)
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let http = response as? HTTPURLResponse else {
            throw MediaAPIError.badResponse
        }
        
        if http.statusCode == 503 {
            throw MediaAPIError.uploadFailed("图片上传服务暂不可用")
        }
        
        guard (200..<300).contains(http.statusCode) else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ MediaAPI upload error: \(errorString)")
            }
            throw MediaAPIError.uploadFailed("图片上传失败")
        }
        
        // Debug: Print raw response
        if let rawString = String(data: data, encoding: .utf8) {
            print("🔵 MediaAPI upload response: \(rawString)")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(ImageUploadResponse.self, from: data)
    }
}
