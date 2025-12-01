import Foundation

public enum AuthAPIError: Error, LocalizedError {
    case invalidURL
    case badResponse(statusCode: Int, message: String?)
    case decodingError
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的请求地址"
        case .badResponse(let statusCode, let message):
            return message ?? "请求失败 (\(statusCode))"
        case .decodingError:
            return "数据解析失败"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

@MainActor
public final class AuthAPI {
    public static let shared = AuthAPI()
    public let baseURL: URL
    
    public init(baseURL: URL = URL(string: "http://localhost:8000")!) {
        self.baseURL = baseURL
    }
    
    // MARK: - Send SMS Verification Code
    
    /// POST /api/v1/auth/sms/send
    public func sendSMS(phone: String) async throws -> SMSSendResponse {
        print("🌐 AuthAPI.sendSMS() called for phone: \(phone.prefix(3))****")
        
        let url = baseURL.appendingPathComponent("/api/v1/auth/sms/send")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = SMSSendRequest(phone: phone)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw AuthAPIError.badResponse(statusCode: 0, message: nil)
        }
        
        print("🌐 AuthAPI.sendSMS() status: \(http.statusCode)")
        
        // SMS send returns 200 for both success and rate limit
        guard http.statusCode == 200 else {
            let errorMessage = try? JSONDecoder().decode(AuthErrorResponse.self, from: data).detail
            throw AuthAPIError.badResponse(statusCode: http.statusCode, message: errorMessage)
        }
        
        return try JSONDecoder().decode(SMSSendResponse.self, from: data)
    }
    
    // MARK: - Verify SMS Code
    
    /// POST /api/v1/auth/sms/verify
    /// If accessToken is provided, it will be included in the Authorization header (for guest -> formal user conversion)
    public func verifySMS(phone: String, code: String, deviceInfo: String?, accessToken: String? = nil) async throws -> SMSVerifyResponse {
        print("🌐 AuthAPI.verifySMS() called")
        
        let url = baseURL.appendingPathComponent("/api/v1/auth/sms/verify")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Include Authorization header if we have a token (guest user binding phone)
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🌐 Including Authorization header for guest user conversion")
        }
        
        let body = SMSVerifyRequest(phone: phone, code: code, deviceInfo: deviceInfo)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw AuthAPIError.badResponse(statusCode: 0, message: nil)
        }
        
        print("🌐 AuthAPI.verifySMS() status: \(http.statusCode)")
        
        guard (200..<300).contains(http.statusCode) else {
            let errorMessage = try? JSONDecoder().decode(AuthErrorResponse.self, from: data).detail
            throw AuthAPIError.badResponse(statusCode: http.statusCode, message: errorMessage)
        }
        
        return try JSONDecoder().decode(SMSVerifyResponse.self, from: data)
    }
    
    // MARK: - Refresh Token
    
    /// POST /api/v1/auth/refresh
    public func refreshToken(refreshToken: String) async throws -> TokenRefreshResponse {
        print("🌐 AuthAPI.refreshToken() called")
        
        let url = baseURL.appendingPathComponent("/api/v1/auth/refresh")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = TokenRefreshRequest(refreshToken: refreshToken)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw AuthAPIError.badResponse(statusCode: 0, message: nil)
        }
        
        print("🌐 AuthAPI.refreshToken() status: \(http.statusCode)")
        
        guard (200..<300).contains(http.statusCode) else {
            let errorMessage = try? JSONDecoder().decode(AuthErrorResponse.self, from: data).detail
            throw AuthAPIError.badResponse(statusCode: http.statusCode, message: errorMessage)
        }
        
        return try JSONDecoder().decode(TokenRefreshResponse.self, from: data)
    }
    
    // MARK: - Get Current User
    
    /// GET /api/v1/auth/me
    public func getCurrentUser(accessToken: String) async throws -> CurrentUserResponse {
        print("🌐 AuthAPI.getCurrentUser() called")
        
        let url = baseURL.appendingPathComponent("/api/v1/auth/me")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw AuthAPIError.badResponse(statusCode: 0, message: nil)
        }
        
        print("🌐 AuthAPI.getCurrentUser() status: \(http.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🌐 Response body: \(responseString)")
        }
        
        guard (200..<300).contains(http.statusCode) else {
            let errorMessage = try? JSONDecoder().decode(AuthErrorResponse.self, from: data).detail
            throw AuthAPIError.badResponse(statusCode: http.statusCode, message: errorMessage)
        }
        
        return try JSONDecoder().decode(CurrentUserResponse.self, from: data)
    }
    
    // MARK: - Logout
    
    /// POST /api/v1/auth/logout
    public func logout(refreshToken: String) async throws -> LogoutResponse {
        print("🌐 AuthAPI.logout() called")
        
        let url = baseURL.appendingPathComponent("/api/v1/auth/logout")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = LogoutRequest(refreshToken: refreshToken)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw AuthAPIError.badResponse(statusCode: 0, message: nil)
        }
        
        print("🌐 AuthAPI.logout() status: \(http.statusCode)")
        
        guard (200..<300).contains(http.statusCode) else {
            let errorMessage = try? JSONDecoder().decode(AuthErrorResponse.self, from: data).detail
            throw AuthAPIError.badResponse(statusCode: http.statusCode, message: errorMessage)
        }
        
        return try JSONDecoder().decode(LogoutResponse.self, from: data)
    }
}
