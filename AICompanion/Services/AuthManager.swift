import Foundation
import Security
import Combine

/// Manages authentication state, token storage (Keychain), and user session
@MainActor
public final class AuthManager: ObservableObject {
    public static let shared = AuthManager()
    
    // MARK: - Keychain Keys
    private enum KeychainKeys {
        static let accessToken = "com.aicompanion.accessToken"
        static let refreshToken = "com.aicompanion.refreshToken"
        static let tokenExpiry = "com.aicompanion.tokenExpiry"
    }
    
    // MARK: - Published State
    @Published public private(set) var isAuthenticated: Bool = false
    @Published public private(set) var isGuest: Bool = false
    @Published public private(set) var hasCompletedOnboarding: Bool = false
    @Published public private(set) var currentUser: CurrentUserResponse?
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var authError: String?
    
    // MARK: - Token State
    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiry: Date?
    
    private init() {
        loadTokensFromKeychain()
    }
    
    // MARK: - Public Token Access
    
    /// Returns the current access token if available and not expired
    public func getAccessToken() async -> String? {
        // Check if token is expired or about to expire (within 60 seconds)
        if let expiry = tokenExpiry, Date().addingTimeInterval(60) >= expiry {
            // Token expired or about to expire, try to refresh
            await refreshAccessToken()
        }
        return accessToken
    }
    
    /// Check if we have a stored token (may need refresh)
    public var hasStoredToken: Bool {
        return accessToken != nil || refreshToken != nil
    }
    
    // MARK: - Token Management
    
    /// Save tokens after successful authentication
    public func saveTokens(accessToken: String, refreshToken: String, expiresIn: Int) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenExpiry = Date().addingTimeInterval(TimeInterval(expiresIn))
        
        saveToKeychain(key: KeychainKeys.accessToken, value: accessToken)
        saveToKeychain(key: KeychainKeys.refreshToken, value: refreshToken)
        saveToKeychain(key: KeychainKeys.tokenExpiry, value: String(tokenExpiry!.timeIntervalSince1970))
        
        isAuthenticated = true
        print("🔐 AuthManager: Tokens saved, expires in \(expiresIn)s")
    }
    
    /// Clear all tokens and reset state (logout)
    public func clearTokens() {
        accessToken = nil
        refreshToken = nil
        tokenExpiry = nil
        currentUser = nil
        isAuthenticated = false
        isGuest = false
        hasCompletedOnboarding = false
        
        deleteFromKeychain(key: KeychainKeys.accessToken)
        deleteFromKeychain(key: KeychainKeys.refreshToken)
        deleteFromKeychain(key: KeychainKeys.tokenExpiry)
        
        // Also clear legacy UserDefaults
        UserDefaults.standard.removeObject(forKey: "onboarding.userId")
        UserDefaults.standard.removeObject(forKey: "onboarding.nickname")
        UserDefaults.standard.removeObject(forKey: "onboarding.completed")
        UserDefaults.standard.removeObject(forKey: "onboarding.step")
        
        print("🔐 AuthManager: Tokens cleared")
    }
    
    /// Update user state after fetching from /auth/me
    public func updateUserState(user: CurrentUserResponse) {
        self.currentUser = user
        self.isGuest = user.isGuest
        self.hasCompletedOnboarding = user.hasCompletedOnboarding
        print("🔐 AuthManager: User state updated - isGuest=\(user.isGuest), hasCompletedOnboarding=\(user.hasCompletedOnboarding)")
    }
    
    // MARK: - Token Refresh
    
    /// Refresh the access token using the refresh token
    public func refreshAccessToken() async {
        guard let currentRefreshToken = refreshToken else {
            print("🔐 AuthManager: No refresh token available")
            clearTokens()
            return
        }
        
        do {
            let response = try await AuthAPI.shared.refreshToken(refreshToken: currentRefreshToken)
            saveTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                expiresIn: response.expiresIn
            )
            print("🔐 AuthManager: Token refreshed successfully")
        } catch {
            print("🔐 AuthManager: Token refresh failed - \(error)")
            clearTokens()
        }
    }
    
    /// Fetch current user info and update state
    public func fetchCurrentUser() async throws {
        isLoading = true
        authError = nil
        
        defer { isLoading = false }
        
        guard let token = await getAccessToken() else {
            throw AuthError.notAuthenticated
        }
        
        do {
            let user = try await AuthAPI.shared.getCurrentUser(accessToken: token)
            updateUserState(user: user)
        } catch {
            authError = error.localizedDescription
            throw error
        }
    }
    
    /// Logout: revoke refresh token and clear local state
    public func logout() async {
        if let currentRefreshToken = refreshToken {
            do {
                _ = try await AuthAPI.shared.logout(refreshToken: currentRefreshToken)
                print("🔐 AuthManager: Logged out from server")
            } catch {
                print("🔐 AuthManager: Server logout failed - \(error)")
            }
        }
        clearTokens()
    }
    
    // MARK: - Keychain Operations
    
    private func loadTokensFromKeychain() {
        accessToken = loadFromKeychain(key: KeychainKeys.accessToken)
        refreshToken = loadFromKeychain(key: KeychainKeys.refreshToken)
        
        if let expiryString = loadFromKeychain(key: KeychainKeys.tokenExpiry),
           let expiryInterval = Double(expiryString) {
            tokenExpiry = Date(timeIntervalSince1970: expiryInterval)
        }
        
        isAuthenticated = accessToken != nil
        print("🔐 AuthManager: Loaded tokens from keychain, isAuthenticated=\(isAuthenticated)")
    }
    
    private func saveToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("🔐 Keychain save error for \(key): \(status)")
        }
    }
    
    private func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Auth Errors

public enum AuthError: Error, LocalizedError {
    case notAuthenticated
    case tokenExpired
    case invalidResponse
    case serverError(String)
    
    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "用户未登录"
        case .tokenExpired:
            return "登录已过期，请重新登录"
        case .invalidResponse:
            return "服务器响应异常"
        case .serverError(let message):
            return message
        }
    }
}
