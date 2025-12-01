import Foundation

// MARK: - Onboarding Submit

public struct OnboardingSubmitRequest: Codable {
    public let nickname: String
    public let birthTime: String
    public let cityId: String
    public let gender: String

    enum CodingKeys: String, CodingKey {
        case nickname
        case birthTime = "birth_time"
        case cityId = "city_id"
        case gender
    }
}

public struct OnboardingSubmitResponse: Codable {
    public let userId: Int
    public let bazi: BaziData?
    public let baziAnalysis: BaziAnalysisResult
    public let personalityTraits: [PersonalityTrait]?
    
    // Token fields (new: guest user receives tokens after onboarding submit)
    public let accessToken: String?
    public let refreshToken: String?
    public let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case bazi = "bazi_data"
        case baziAnalysis = "bazi_analysis"
        case personalityTraits = "personality_traits"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

// MARK: - Feedback

public struct TraitFeedback: Codable {
    public let traitId: Int
    public let feedbackFlag: String
    public let comment: String?

    enum CodingKeys: String, CodingKey {
        case traitId = "trait_id"
        case feedbackFlag = "feedback_flag"
        case comment
    }

    public init(traitId: Int, feedbackFlag: String, comment: String? = nil) {
        self.traitId = traitId
        self.feedbackFlag = feedbackFlag
        self.comment = comment
    }
}

public struct OnboardingFeedbackRequest: Codable {
    public let userId: Int
    public let traitFeedbacks: [TraitFeedback]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case traitFeedbacks = "trait_feedbacks"
    }

    public init(userId: Int, traitFeedbacks: [TraitFeedback]) {
        self.userId = userId
        self.traitFeedbacks = traitFeedbacks
    }
}

public struct OnboardingFeedbackResponse: Codable {
    public let status: String
    public let message: String
}

// MARK: - KYC Skip

public struct OnboardingSkipRequest: Codable {
    public let userId: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }

    public init(userId: Int) {
        self.userId = userId
    }
}

public struct OnboardingSkipResponse: Codable {
    public let status: String
    public let message: String
}

// MARK: - KYC Message

public struct KYCChatMessage: Codable {
    /// Backend expects: { "role": "user"|"assistant", "content": "..." }
    public enum Role: String, Codable {
        case user
        case assistant
    }

    public let role: Role
    public let content: String

    enum CodingKeys: String, CodingKey {
        case role
        case content
    }

    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}

public struct KYCMessageRequest: Codable {
    public let userId: Int
    public let message: String
    public let history: [KYCChatMessage]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case message
        case history
    }

    public init(userId: Int, message: String, history: [KYCChatMessage]) {
        self.userId = userId
        self.message = message
        self.history = history
    }
}

public struct KYCMessageResponse: Codable {
    public let reply: String
    public let collectionStatus: String
    public let kycCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case reply
        case collectionStatus = "collection_status"
        case kycCompleted = "kyc_completed"
    }
}
