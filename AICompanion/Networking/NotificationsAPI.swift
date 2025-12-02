import Foundation
import UIKit

// MARK: - Request/Response Models

public struct DeviceTokenRequest: Codable {
    public let deviceId: String
    public let platform: String
    public let pushToken: String
    public let pushProvider: String
    public let appVersion: String?
    public let osVersion: String?
    public let deviceModel: String?
    
    public init(deviceId: String, pushToken: String) {
        self.deviceId = deviceId
        self.platform = "ios"
        self.pushToken = pushToken
        self.pushProvider = "apns"
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        self.osVersion = UIDevice.current.systemVersion
        self.deviceModel = UIDevice.current.model
    }
    
    enum CodingKeys: String, CodingKey {
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
    public let deviceId: String
    
    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
    }
}

public struct UnregisterDeviceResponse: Codable {
    public let success: Bool
}

// MARK: - Notifications API

/// Notifications API - All endpoints require authentication
@MainActor
public final class NotificationsAPI {
    public static let shared = NotificationsAPI()
    private let client = APIClient.shared
    
    private init() {}
    
    /// POST /api/v1/notifications/device-token
    /// Register or update a device push token.
    public func registerDeviceToken(pushToken: String) async throws -> DeviceTokenResponse {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let request = DeviceTokenRequest(deviceId: deviceId, pushToken: pushToken)
        return try await client.post(path: "/api/v1/notifications/device-token", body: request)
    }
    
    /// DELETE /api/v1/notifications/device-token
    /// Unregister a device token (mark as inactive).
    public func unregisterDeviceToken() async throws -> UnregisterDeviceResponse {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let request = UnregisterDeviceRequest(deviceId: deviceId)
        return try await client.delete(path: "/api/v1/notifications/device-token", body: request)
    }
    
    // MARK: - Deprecated (use methods without userId)
    
    @available(*, deprecated, message: "Use registerDeviceToken(pushToken:) instead - userId is now derived from token")
    public func registerDeviceToken(userId: Int, pushToken: String) async throws -> DeviceTokenResponse {
        try await registerDeviceToken(pushToken: pushToken)
    }
    
    @available(*, deprecated, message: "Use unregisterDeviceToken() instead - userId is now derived from token")
    public func unregisterDeviceToken(userId: Int) async throws -> Bool {
        let response = try await unregisterDeviceToken()
        return response.success
    }
}
