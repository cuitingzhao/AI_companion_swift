import Foundation

// MARK: - SMS Send

public struct SMSSendRequest: Codable {
    public let phone: String
    
    public init(phone: String) {
        self.phone = phone
    }
}

public struct SMSSendResponse: Codable {
    public let success: Bool
    public let message: String
    public let retryAfter: Int?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case retryAfter = "retry_after"
    }
}

// MARK: - SMS Verify

public struct SMSVerifyRequest: Codable {
    public let phone: String
    public let code: String
    public let deviceInfo: String?
    
    enum CodingKeys: String, CodingKey {
        case phone
        case code
        case deviceInfo = "device_info"
    }
    
    public init(phone: String, code: String, deviceInfo: String? = nil) {
        self.phone = phone
        self.code = code
        self.deviceInfo = deviceInfo
    }
}

public struct SMSVerifyResponse: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let tokenType: String
    public let expiresIn: Int
    public let user: UserBasicInfo
    public let isNewUser: Bool
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case user
        case isNewUser = "is_new_user"
    }
}

// MARK: - User Basic Info

public struct UserBasicInfo: Codable {
    public let id: Int
    public let nickname: String
    public let avatarUrl: String?
    public let isGuest: Bool
    public let phone: String?
    public let hasWechat: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case nickname
        case avatarUrl = "avatar_url"
        case isGuest = "is_guest"
        case phone
        case hasWechat = "has_wechat"
    }
}

// MARK: - Token Refresh

public struct TokenRefreshRequest: Codable {
    public let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
    
    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

public struct TokenRefreshResponse: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let tokenType: String
    public let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

// MARK: - Current User (GET /auth/me)

public struct CurrentUserResponse: Codable {
    public let id: Int
    public let nickname: String
    public let avatarUrl: String?
    public let phone: String?
    public let phoneVerified: Bool
    public let hasWechat: Bool
    public let isGuest: Bool
    public let isActive: Bool
    public let hasCompletedOnboarding: Bool
    public let createdAt: String
    public let lastLoginAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case nickname
        case avatarUrl = "avatar_url"
        case phone
        case phoneVerified = "phone_verified"
        case hasWechat = "has_wechat"
        case isGuest = "is_guest"
        case isActive = "is_active"
        case hasCompletedOnboarding = "has_completed_onboarding"
        case createdAt = "created_at"
        case lastLoginAt = "last_login_at"
    }
}

// MARK: - Logout

public struct LogoutRequest: Codable {
    public let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
    
    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

public struct LogoutResponse: Codable {
    public let success: Bool
    public let message: String
}

// MARK: - Error Response

public struct AuthErrorResponse: Codable {
    public let detail: String
}
