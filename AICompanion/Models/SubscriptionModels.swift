import Foundation

// MARK: - Subscription Status

/// Subscription status from backend (named differently to avoid StoreKit conflict)
public struct AppSubscriptionStatus: Codable {
    public let hasAccess: Bool
    public let status: SubscriptionState
    public let planType: PlanType?
    public let trialEndsAt: String?
    public let subscriptionEndsAt: String?
    public let daysRemaining: Int?
    public let autoRenewEnabled: Bool
    
    enum CodingKeys: String, CodingKey {
        case hasAccess = "has_access"
        case status
        case planType = "plan_type"
        case trialEndsAt = "trial_ends_at"
        case subscriptionEndsAt = "subscription_ends_at"
        case daysRemaining = "days_remaining"
        case autoRenewEnabled = "auto_renew_enabled"
    }
    
    /// Parsed trial end date
    public var trialEndDate: Date? {
        guard let dateString = trialEndsAt else { return nil }
        return ISO8601DateFormatter().date(from: dateString)
    }
    
    /// Parsed subscription end date
    public var subscriptionEndDate: Date? {
        guard let dateString = subscriptionEndsAt else { return nil }
        return ISO8601DateFormatter().date(from: dateString)
    }
}

// MARK: - Subscription State

public enum SubscriptionState: String, Codable {
    case trial = "trial"
    case active = "active"
    case expired = "expired"
    case cancelled = "cancelled"
    
    public var displayName: String {
        switch self {
        case .trial: return "试用中"
        case .active: return "已订阅"
        case .expired: return "已过期"
        case .cancelled: return "已取消"
        }
    }
}

// MARK: - Plan Type

public enum PlanType: String, Codable {
    case monthly = "monthly"
    case yearly = "yearly"
    
    public var displayName: String {
        switch self {
        case .monthly: return "月度会员"
        case .yearly: return "年度会员"
        }
    }
}

// MARK: - Verify Receipt

public struct VerifyReceiptRequest: Encodable {
    public let receiptData: String
    
    enum CodingKeys: String, CodingKey {
        case receiptData = "receipt_data"
    }
    
    public init(receiptData: String) {
        self.receiptData = receiptData
    }
}

public struct VerifyReceiptResponse: Codable {
    public let success: Bool
    public let message: String?
    public let subscription: AppSubscriptionStatus?
}

// MARK: - Restore Purchase

public struct RestoreRequest: Encodable {
    public let receiptData: String
    
    enum CodingKeys: String, CodingKey {
        case receiptData = "receipt_data"
    }
    
    public init(receiptData: String) {
        self.receiptData = receiptData
    }
}

public struct RestoreResponse: Codable {
    public let success: Bool
    public let message: String?
    public let subscription: AppSubscriptionStatus?
}

// MARK: - Product Identifiers

public enum SubscriptionProductID: String, CaseIterable {
    case monthly = "ai.dors.AICompanion.monthly_premium"
    case yearly = "ai.dors.AICompanion.yearly_premium"
    
    public var planType: PlanType {
        switch self {
        case .monthly: return .monthly
        case .yearly: return .yearly
        }
    }
    
    public static var allIdentifiers: Set<String> {
        Set(allCases.map { $0.rawValue })
    }
}
