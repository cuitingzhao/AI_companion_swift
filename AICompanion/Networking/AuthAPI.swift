import Foundation

/// Auth API - Mixed auth requirements
/// Most endpoints don't require auth (they ARE the auth endpoints)
/// Only /me requires auth
@MainActor
public final class AuthAPI {
    public static let shared = AuthAPI()
    private let client = APIClient.shared
    
    private init() {}
    
    // MARK: - Send SMS Verification Code
    
    /// POST /api/v1/auth/sms/send - NO AUTH REQUIRED
    public func sendSMS(phone: String) async throws -> SMSSendResponse {
        print("🌐 AuthAPI.sendSMS() called for phone: \(phone.prefix(3))****")
        let body = SMSSendRequest(phone: phone)
        return try await client.post(path: "/api/v1/auth/sms/send", body: body, requiresAuth: false)
    }
    
    // MARK: - Verify SMS Code
    
    /// POST /api/v1/auth/sms/verify - OPTIONAL AUTH
    /// If accessToken is provided, it will be included in the Authorization header (for guest -> formal user conversion)
    public func verifySMS(phone: String, code: String, deviceInfo: String?, accessToken: String? = nil) async throws -> SMSVerifyResponse {
        print("🌐 AuthAPI.verifySMS() called")
        
        // Build request manually since we need custom auth handling
        var request = await client.makeRequest(
            path: "/api/v1/auth/sms/verify",
            method: "POST",
            body: try JSONEncoder().encode(SMSVerifyRequest(phone: phone, code: code, deviceInfo: deviceInfo)),
            requiresAuth: false  // We handle auth manually below
        )
        
        // Include Authorization header if we have a token (guest user binding phone)
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🌐 Including Authorization header for guest user conversion")
        }
        
        return try await client.perform(request)
    }
    
    // MARK: - Refresh Token
    
    /// POST /api/v1/auth/refresh - NO AUTH REQUIRED
    public func refreshToken(refreshToken: String) async throws -> TokenRefreshResponse {
        print("🌐 AuthAPI.refreshToken() called")
        let body = TokenRefreshRequest(refreshToken: refreshToken)
        return try await client.post(path: "/api/v1/auth/refresh", body: body, requiresAuth: false)
    }
    
    // MARK: - Get Current User
    
    /// GET /api/v1/auth/me - AUTH REQUIRED (but we pass token explicitly)
    public func getCurrentUser(accessToken: String) async throws -> CurrentUserResponse {
        print("🌐 AuthAPI.getCurrentUser() called")
        
        // Build request with explicit token
        var request = await client.makeRequest(
            path: "/api/v1/auth/me",
            method: "GET",
            requiresAuth: false  // We set auth manually
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        return try await client.perform(request)
    }
    
    // MARK: - Logout
    
    /// POST /api/v1/auth/logout - NO AUTH REQUIRED (uses refresh token in body)
    public func logout(refreshToken: String) async throws -> LogoutResponse {
        print("🌐 AuthAPI.logout() called")
        let body = LogoutRequest(refreshToken: refreshToken)
        return try await client.post(path: "/api/v1/auth/logout", body: body, requiresAuth: false)
    }
}
