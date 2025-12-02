import Foundation

/// Subscription API - All endpoints require authentication
@MainActor
public final class SubscriptionAPI {
    public static let shared = SubscriptionAPI()
    private let client = APIClient.shared
    
    private init() {}
    
    /// GET /api/v1/subscription/status
    /// Fetches the current user's subscription status
    public func getStatus() async throws -> AppSubscriptionStatus {
        try await client.get(path: "/api/v1/subscription/status")
    }
    
    /// POST /api/v1/subscription/verify-receipt
    /// Verifies an Apple IAP receipt with the backend
    public func verifyReceipt(receiptData: String) async throws -> VerifyReceiptResponse {
        let body = VerifyReceiptRequest(receiptData: receiptData)
        return try await client.post(path: "/api/v1/subscription/verify-receipt", body: body)
    }
    
    /// POST /api/v1/subscription/restore
    /// Restores a previous Apple IAP purchase
    public func restorePurchase(receiptData: String) async throws -> RestoreResponse {
        let body = RestoreRequest(receiptData: receiptData)
        return try await client.post(path: "/api/v1/subscription/restore", body: body)
    }
}
