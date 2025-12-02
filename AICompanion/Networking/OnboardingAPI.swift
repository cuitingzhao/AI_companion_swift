import Foundation

/// Onboarding API - Mixed auth requirements
/// - submit: NO auth required (creates guest user)
/// - feedback, message, skip, status: Auth required
@MainActor
public final class OnboardingAPI {
    public static let shared = OnboardingAPI()
    private let client = APIClient.shared
    
    private init() {}
    
    /// POST /api/v1/onboarding/submit - NO AUTH REQUIRED
    /// Creates a guest user account with bazi info
    public func submit(_ request: OnboardingSubmitRequest) async throws -> OnboardingSubmitResponse {
        print("🌐 OnboardingAPI.submit() called")
        return try await client.post(path: "/api/v1/onboarding/submit", body: request, requiresAuth: false)
    }
    
    /// POST /api/v1/onboarding/feedback - AUTH REQUIRED
    /// Submit personality trait feedback
    public func submitFeedback(_ request: OnboardingFeedbackRequest) async throws -> OnboardingFeedbackResponse {
        print("🌐 OnboardingAPI.submitFeedback() called")
        return try await client.post(path: "/api/v1/onboarding/feedback", body: request)
    }
    
    /// POST /api/v1/onboarding/message - AUTH REQUIRED
    /// Send KYC chat message
    public func sendKYCMessage(_ request: KYCMessageRequest) async throws -> KYCMessageResponse {
        print("🌐 OnboardingAPI.sendKYCMessage() called")
        return try await client.post(path: "/api/v1/onboarding/message", body: request)
    }
    
    /// POST /api/v1/onboarding/message/location - AUTH REQUIRED
    /// Send KYC location message
    public func sendKYCLocationMessage(_ request: KYCLocationMessageRequest) async throws -> KYCMessageResponse {
        print("🌐 OnboardingAPI.sendKYCLocationMessage() called")
        return try await client.post(path: "/api/v1/onboarding/message/location", body: request)
    }
    
    /// POST /api/v1/onboarding/skip - AUTH REQUIRED
    /// Skip KYC onboarding
    public func skip(_ request: OnboardingSkipRequest) async throws -> OnboardingSkipResponse {
        print("🌐 OnboardingAPI.skip() called")
        return try await client.post(path: "/api/v1/onboarding/skip", body: request)
    }
    
    /// GET /api/v1/onboarding/status - AUTH REQUIRED
    /// Get KYC onboarding status
    public func getStatus() async throws -> OnboardingStatusResponse {
        print("🌐 OnboardingAPI.getStatus() called")
        return try await client.get(path: "/api/v1/onboarding/status")
    }
    
    // MARK: - Deprecated
    
    @available(*, deprecated, message: "Use getStatus() - userId derived from token")
    public func getStatus(userId: Int) async throws -> OnboardingStatusResponse {
        return try await getStatus()
    }
}

/// KYC Location Message Request
public struct KYCLocationMessageRequest: Encodable {
    public let latitude: Double
    public let longitude: Double
    
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// Onboarding Status Response
public struct OnboardingStatusResponse: Decodable {
    public let hasCompletedKyc: Bool
    public let kycProgress: String?
    
    enum CodingKeys: String, CodingKey {
        case hasCompletedKyc = "has_completed_kyc"
        case kycProgress = "kyc_progress"
    }
}
