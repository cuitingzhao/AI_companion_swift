import Foundation
import StoreKit
import Combine

/// Manages subscription state and StoreKit purchases
@MainActor
public final class SubscriptionManager: ObservableObject {
    public static let shared = SubscriptionManager()
    
    // MARK: - Published Properties
    
    @Published public private(set) var subscriptionStatus: AppSubscriptionStatus?
    @Published public private(set) var products: [Product] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var purchaseError: String?
    
    // MARK: - Computed Properties
    
    /// Whether the user has access to the app (trial or active subscription)
    public var hasAccess: Bool {
        subscriptionStatus?.hasAccess ?? false
    }
    
    /// Whether the user is in trial period
    public var isInTrial: Bool {
        subscriptionStatus?.status == .trial
    }
    
    /// Days remaining in trial or subscription
    public var daysRemaining: Int? {
        subscriptionStatus?.daysRemaining
    }
    
    /// Monthly product
    public var monthlyProduct: Product? {
        products.first { $0.id == SubscriptionProductID.monthly.rawValue }
    }
    
    /// Yearly product
    public var yearlyProduct: Product? {
        products.first { $0.id == SubscriptionProductID.yearly.rawValue }
    }
    
    // MARK: - Private Properties
    
    private var updateListenerTask: Task<Void, Error>?
    
    // MARK: - Initialization
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Loads products and subscription status
    public func initialize() async {
        await loadProducts()
        await refreshSubscriptionStatus()
    }
    
    /// Loads available subscription products from App Store
    public func loadProducts() async {
        do {
            let productIds = SubscriptionProductID.allIdentifiers
            products = try await Product.products(for: productIds)
            print("📦 Loaded \(products.count) subscription products")
            
            for product in products {
                print("  - \(product.id): \(product.displayPrice)")
            }
        } catch {
            print("❌ Failed to load products: \(error)")
        }
    }
    
    /// Refreshes subscription status from backend
    public func refreshSubscriptionStatus() async {
        do {
            subscriptionStatus = try await SubscriptionAPI.shared.getStatus()
            print("📦 Subscription status: \(subscriptionStatus?.status.rawValue ?? "unknown"), hasAccess: \(hasAccess)")
        } catch {
            print("❌ Failed to get subscription status: \(error)")
            // Don't clear status on error - keep cached value
        }
    }
    
    /// Purchases a subscription product
    /// - Parameter product: The product to purchase
    /// - Returns: Whether the purchase was successful
    @discardableResult
    public func purchase(_ product: Product) async -> Bool {
        isLoading = true
        purchaseError = nil
        
        defer { isLoading = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                // Verify with backend
                let success = await verifyWithBackend()
                
                if success {
                    await transaction.finish()
                    await refreshSubscriptionStatus()
                    return true
                } else {
                    purchaseError = "订阅验证失败，请稍后重试"
                    return false
                }
                
            case .userCancelled:
                print("📦 User cancelled purchase")
                return false
                
            case .pending:
                print("📦 Purchase pending approval")
                purchaseError = "购买待审批"
                return false
                
            @unknown default:
                purchaseError = "未知错误"
                return false
            }
        } catch {
            print("❌ Purchase failed: \(error)")
            purchaseError = error.localizedDescription
            return false
        }
    }
    
    /// Restores previous purchases
    /// - Returns: Whether restoration was successful
    @discardableResult
    public func restorePurchases() async -> Bool {
        isLoading = true
        purchaseError = nil
        
        defer { isLoading = false }
        
        do {
            // Sync with App Store
            try await AppStore.sync()
            
            // Get receipt and send to backend
            guard let receiptData = getReceiptData() else {
                purchaseError = "无法获取购买凭证"
                return false
            }
            
            let response = try await SubscriptionAPI.shared.restorePurchase(receiptData: receiptData)
            
            if response.success {
                if let subscription = response.subscription {
                    subscriptionStatus = subscription
                }
                return true
            } else {
                purchaseError = response.message ?? "恢复购买失败"
                return false
            }
        } catch {
            print("❌ Restore failed: \(error)")
            purchaseError = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Private Methods
    
    /// Listens for transaction updates (renewals, refunds, etc.)
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    // Verify with backend
                    await self.verifyWithBackend()
                    await self.refreshSubscriptionStatus()
                    
                    await transaction.finish()
                } catch {
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    /// Verifies a StoreKit verification result
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    /// Gets the App Store receipt data as base64 string
    private func getReceiptData() -> String? {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            return nil
        }
        return receiptData.base64EncodedString()
    }
    
    /// Verifies the current receipt with the backend
    @discardableResult
    private func verifyWithBackend() async -> Bool {
        guard let receiptData = getReceiptData() else {
            print("❌ No receipt data available")
            return false
        }
        
        do {
            let response = try await SubscriptionAPI.shared.verifyReceipt(receiptData: receiptData)
            
            if response.success {
                if let subscription = response.subscription {
                    subscriptionStatus = subscription
                }
                return true
            } else {
                print("❌ Receipt verification failed: \(response.message ?? "Unknown error")")
                return false
            }
        } catch {
            print("❌ Receipt verification error: \(error)")
            return false
        }
    }
}

// MARK: - Product Extensions

extension Product {
    /// Formatted price per month for comparison
    var monthlyEquivalent: String {
        if id == SubscriptionProductID.yearly.rawValue {
            // Calculate monthly equivalent for yearly plan
            let monthlyPrice = price / 12
            return monthlyPrice.formatted(.currency(code: priceFormatStyle.currencyCode ?? "CNY"))
        }
        return displayPrice
    }
    
    /// Savings percentage for yearly plan
    var savingsPercentage: Int? {
        guard id == SubscriptionProductID.yearly.rawValue else { return nil }
        // Assuming monthly is ¥18, yearly is ¥88
        // Monthly for a year = 18 * 12 = 216
        // Yearly = 88
        // Savings = (216 - 88) / 216 = 59%
        let monthlyAnnual = Decimal(18 * 12)
        let savings = (monthlyAnnual - price) / monthlyAnnual * 100
        return Int(truncating: savings as NSNumber)
    }
}
