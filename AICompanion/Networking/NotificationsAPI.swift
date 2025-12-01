import Foundation
import UIKit

// MARK: - Request/Response Models

public struct DeviceTokenRequest: Codable {
    public let userId: Int
    public let deviceId: String
    public let platform: String
    public let pushToken: String
    public let pushProvider: String
    public let appVersion: String?
    public let osVersion: String?
    public let deviceModel: String?
    
    public init(userId: Int, deviceId: String, pushToken: String) {
        self.userId = userId
        self.deviceId = deviceId
        self.platform = "ios"
        self.pushToken = pushToken
        self.pushProvider = "apns"
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        self.osVersion = UIDevice.current.systemVersion
        self.deviceModel = UIDevice.current.model
    }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case deviceId = "device_id"
        case platform
        case pushToken = "push_token"
        case pushProvider = "push_provider"
        case appVersion = "app_version"
        case osVersion = "os_version"
        case deviceModel = "device_model"
    }
}

public struct DeviceTokenResponse: Codable {
    public let id: Int
    public let userId: Int
    public let deviceId: String
    public let platform: String
    public let pushProvider: String
    public let isActive: Bool
    public let createdAt: String
    public let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case deviceId = "device_id"
        case platform
        case pushProvider = "push_provider"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public struct UnregisterDeviceRequest: Codable {
    public let userId: Int
    public let deviceId: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case deviceId = "device_id"
    }
}

public struct UnregisterDeviceResponse: Codable {
    public let success: Bool
}

// MARK: - Notifications API

public enum NotificationsAPIError: Error {
    case invalidURL
    case badResponse
    case decodingError
    case registrationFailed(String)
}

@MainActor
public final class NotificationsAPI {
    public static let shared = NotificationsAPI()
    public let baseURL: URL
    
    public init(baseURL: URL = URL(string: "http://localhost:8000")!) {
        self.baseURL = baseURL
    }
    
    /// POST /api/v1/notifications/device-token
    /// Register or update a device push token.
    public func registerDeviceToken(userId: Int, pushToken: String) async throws -> DeviceTokenResponse {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/notifications/device-token"
        
        guard let url = components.url else {
            throw NotificationsAPIError.invalidURL
        }
        
        // Get device ID
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let request = DeviceTokenRequest(userId: userId, deviceId: deviceId, pushToken: pushToken)
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let http = response as? HTTPURLResponse else {
            throw NotificationsAPIError.badResponse
        }
        
        guard (200..<300).contains(http.statusCode) else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ NotificationsAPI register error: \(errorString)")
            }
            throw NotificationsAPIError.registrationFailed("设备注册失败")
        }
        
        // Debug: Print raw response
        if let rawString = String(data: data, encoding: .utf8) {
            print("🔔 NotificationsAPI register response: \(rawString)")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(DeviceTokenResponse.self, from: data)
    }
    
    /// DELETE /api/v1/notifications/device-token
    /// Unregister a device token (mark as inactive).
    public func unregisterDeviceToken(userId: Int) async throws -> Bool {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/notifications/device-token"
        
        guard let url = components.url else {
            throw NotificationsAPIError.invalidURL
        }
        
        // Get device ID
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let request = UnregisterDeviceRequest(userId: userId, deviceId: deviceId)
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let http = response as? HTTPURLResponse else {
            throw NotificationsAPIError.badResponse
        }
        
        guard (200..<300).contains(http.statusCode) else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ NotificationsAPI unregister error: \(errorString)")
            }
            return false
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(UnregisterDeviceResponse.self, from: data)
        return result.success
    }
}
