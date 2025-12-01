import Foundation

/// Shared API client that handles common functionality like authentication headers
@MainActor
public final class APIClient {
    public static let shared = APIClient()
    public let baseURL: URL
    
    public init(baseURL: URL = URL(string: "http://localhost:8000")!) {
        self.baseURL = baseURL
    }
    
    // MARK: - Request Building
    
    /// Creates a URLRequest with common headers and optional authentication
    public func makeRequest(
        path: String,
        method: String = "GET",
        body: Data? = nil,
        requiresAuth: Bool = true
    ) async -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = body
        }
        
        // Add Authorization header if we have a token
        if requiresAuth, let token = await AuthManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    /// Creates a URLRequest from URLComponents with optional authentication
    public func makeRequest(
        components: URLComponents,
        method: String = "GET",
        body: Data? = nil,
        requiresAuth: Bool = true
    ) async -> URLRequest? {
        guard let url = components.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = body
        }
        
        // Add Authorization header if we have a token
        if requiresAuth, let token = await AuthManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    // MARK: - Convenience Methods
    
    /// Performs a GET request
    public func get<T: Decodable>(
        path: String,
        requiresAuth: Bool = true
    ) async throws -> T {
        let request = await makeRequest(path: path, method: "GET", requiresAuth: requiresAuth)
        return try await perform(request)
    }
    
    /// Performs a POST request with an encodable body
    public func post<T: Decodable, B: Encodable>(
        path: String,
        body: B,
        requiresAuth: Bool = true
    ) async throws -> T {
        let bodyData = try JSONEncoder().encode(body)
        let request = await makeRequest(path: path, method: "POST", body: bodyData, requiresAuth: requiresAuth)
        return try await perform(request)
    }
    
    /// Performs a PATCH request with an encodable body
    public func patch<T: Decodable, B: Encodable>(
        path: String,
        body: B,
        requiresAuth: Bool = true
    ) async throws -> T {
        let bodyData = try JSONEncoder().encode(body)
        let request = await makeRequest(path: path, method: "PATCH", body: bodyData, requiresAuth: requiresAuth)
        return try await perform(request)
    }
    
    /// Performs a DELETE request
    public func delete<T: Decodable>(
        path: String,
        requiresAuth: Bool = true
    ) async throws -> T {
        let request = await makeRequest(path: path, method: "DELETE", requiresAuth: requiresAuth)
        return try await perform(request)
    }
    
    // MARK: - Request Execution
    
    /// Performs a URLRequest and decodes the response
    public func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Log for debugging
        if let url = request.url {
            print("🌐 \(request.httpMethod ?? "GET") \(url.path) → \(http.statusCode)")
        }
        
        // Handle 401 Unauthorized - token might be expired
        if http.statusCode == 401 {
            // Try to refresh token and retry once
            await AuthManager.shared.refreshAccessToken()
            
            // Check if we got a new token
            if let newToken = await AuthManager.shared.getAccessToken() {
                var retryRequest = request
                retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                
                let (retryData, retryResponse) = try await URLSession.shared.data(for: retryRequest)
                
                guard let retryHttp = retryResponse as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if retryHttp.statusCode == 401 {
                    // Still unauthorized after refresh, clear tokens
                    AuthManager.shared.clearTokens()
                    throw APIError.unauthorized
                }
                
                guard (200..<300).contains(retryHttp.statusCode) else {
                    throw APIError.httpError(statusCode: retryHttp.statusCode, data: retryData)
                }
                
                return try JSONDecoder().decode(T.self, from: retryData)
            } else {
                throw APIError.unauthorized
            }
        }
        
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.httpError(statusCode: http.statusCode, data: data)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - API Errors

public enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的请求地址"
        case .invalidResponse:
            return "服务器响应异常"
        case .unauthorized:
            return "登录已过期，请重新登录"
        case .httpError(let statusCode, let data):
            // Try to extract error message from response
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                return errorResponse.detail
            }
            return "请求失败 (\(statusCode))"
        case .decodingError(let error):
            return "数据解析失败: \(error.localizedDescription)"
        }
    }
}

// MARK: - Error Response

private struct ErrorResponse: Decodable {
    let detail: String
}
