import Foundation

/// API client for subscription-related endpoints
@MainActor
public final class SubscriptionAPI {
    public static let shared = SubscriptionAPI()
    private let baseURL = URL(string: "http://localhost:8000")!
    
    private init() {}
    
    // MARK: - Get Subscription Status
    
    /// Fetches the current user's subscription status
    /// - Returns: AppSubscriptionStatus containing access info, plan type, and expiry dates
    public func getStatus() async throws -> AppSubscriptionStatus {
        let url = baseURL.appendingPathComponent("/api/v1/subscription/status")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth header
        if let token = await AuthManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw SubscriptionAPIError.invalidResponse
        }
        
        print("📦 GET /subscription/status → \(http.statusCode)")
        
        // Handle 401 - try to refresh token
        if http.statusCode == 401 {
            await AuthManager.shared.refreshAccessToken()
            
            if let newToken = await AuthManager.shared.getAccessToken() {
                request.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                let (retryData, retryResponse) = try await URLSession.shared.data(for: request)
                
                guard let retryHttp = retryResponse as? HTTPURLResponse,
                      (200..<300).contains(retryHttp.statusCode) else {
                    throw SubscriptionAPIError.unauthorized
                }
                
                return try JSONDecoder().decode(AppSubscriptionStatus.self, from: retryData)
            }
            throw SubscriptionAPIError.unauthorized
        }
        
        guard (200..<300).contains(http.statusCode) else {
            throw SubscriptionAPIError.httpError(statusCode: http.statusCode)
        }
        
        return try JSONDecoder().decode(AppSubscriptionStatus.self, from: data)
    }
    
    // MARK: - Verify Receipt
    
    /// Verifies an Apple IAP receipt with the backend
    /// - Parameter receiptData: Base64-encoded receipt data
    /// - Returns: VerifyReceiptResponse with success status and updated subscription
    public func verifyReceipt(receiptData: String) async throws -> VerifyReceiptResponse {
        let url = baseURL.appendingPathComponent("/api/v1/subscription/verify-receipt")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth header
        if let token = await AuthManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = VerifyReceiptRequest(receiptData: receiptData)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw SubscriptionAPIError.invalidResponse
        }
        
        print("📦 POST /subscription/verify-receipt → \(http.statusCode)")
        
        // Handle 401
        if http.statusCode == 401 {
            throw SubscriptionAPIError.unauthorized
        }
        
        guard (200..<300).contains(http.statusCode) else {
            throw SubscriptionAPIError.httpError(statusCode: http.statusCode)
        }
        
        return try JSONDecoder().decode(VerifyReceiptResponse.self, from: data)
    }
    
    // MARK: - Restore Purchase
    
    /// Restores a previous Apple IAP purchase
    /// - Parameter receiptData: Base64-encoded receipt data
    /// - Returns: RestoreResponse with success status and restored subscription
    public func restorePurchase(receiptData: String) async throws -> RestoreResponse {
        let url = baseURL.appendingPathComponent("/api/v1/subscription/restore")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth header
        if let token = await AuthManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = RestoreRequest(receiptData: receiptData)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw SubscriptionAPIError.invalidResponse
        }
        
        print("📦 POST /subscription/restore → \(http.statusCode)")
        
        // Handle 401
        if http.statusCode == 401 {
            throw SubscriptionAPIError.unauthorized
        }
        
        guard (200..<300).contains(http.statusCode) else {
            throw SubscriptionAPIError.httpError(statusCode: http.statusCode)
        }
        
        return try JSONDecoder().decode(RestoreResponse.self, from: data)
    }
}

// MARK: - Errors

public enum SubscriptionAPIError: Error, LocalizedError {
    case invalidResponse
    case unauthorized
    case httpError(statusCode: Int)
    case verificationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "服务器响应异常"
        case .unauthorized:
            return "登录已过期，请重新登录"
        case .httpError(let statusCode):
            return "请求失败 (\(statusCode))"
        case .verificationFailed(let message):
            return message
        }
    }
}
