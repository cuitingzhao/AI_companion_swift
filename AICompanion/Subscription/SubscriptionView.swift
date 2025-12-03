import SwiftUI
import StoreKit

/// Paywall view for subscription purchase
public struct SubscriptionView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedPlan: SubscriptionProductID = .yearly
    @State private var showError: Bool = false
    
    private let onSubscribed: () -> Void
    private let onClose: (() -> Void)?
    
    public init(
        onSubscribed: @escaping () -> Void,
        onClose: (() -> Void)? = nil
    ) {
        self.onSubscribed = onSubscribed
        self.onClose = onClose
    }
    
    public var body: some View {
        ZStack {
            // Background
            AppColors.accentYellow
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header with mascot
                    headerSection
                    
                    // Value proposition
                    valuePropositionSection
                    
                    // Plan cards
                    planCardsSection
                    
                    // Subscribe button
                    subscribeButton
                    
                    // Restore purchase
                    restoreButton
                    
                    // Terms and privacy
                    termsSection
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
            }
            
            // Close button (if allowed)
            if let close = onClose {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: close) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(AppColors.textMedium)
                                .frame(width: 36, height: 36)
                                .background(AppColors.bgCream)
                                .clipShape(Circle())
                                .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    Spacer()
                }
            }
            
            // Loading overlay
            if subscriptionManager.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("处理中...")
                        .font(AppFonts.body)
                        .foregroundStyle(.white)
                }
            }
        }
        .task {
            await subscriptionManager.loadProducts()
        }
        .alert("购买失败", isPresented: $showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(subscriptionManager.purchaseError ?? "请稍后重试")
        }
        .onChange(of: subscriptionManager.purchaseError) { _, newValue in
            showError = newValue != nil
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            GIFImage(name: "winking")
                .frame(width: 120, height: 80)
            
            Text("让点点继续陪伴你")
                .font(AppFonts.title)
                .foregroundStyle(AppColors.textBlack)
            
            if let daysRemaining = subscriptionManager.daysRemaining,
               subscriptionManager.isInTrial {
                Text("试用期还剩 \(daysRemaining) 天")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.accentCoral)
            } else {
                Text("试用期已结束")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.accentCoral)
            }
        }
    }
    
    // MARK: - Value Proposition
    
    private var valuePropositionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FeatureRow(icon: "sparkles", text: "助你趋利避害的伙伴")
            FeatureRow(icon: "target", text: "帮你实现目标的伙伴")
            FeatureRow(icon: "calendar", text: "提醒你完成任务的伙伴")
            FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "更多贴心功能即将上线")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                .fill(.white)
                .shadow(color: AppColors.shadowColor, radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Plan Cards
    
    private var planCardsSection: some View {
        VStack(spacing: 12) {
            // Yearly plan (recommended)
            if let yearly = subscriptionManager.yearlyProduct {
                PlanCard(
                    product: yearly,
                    isSelected: selectedPlan == .yearly,
                    isRecommended: true,
                    onSelect: { selectedPlan = .yearly }
                )
            }
            
            // Monthly plan
            if let monthly = subscriptionManager.monthlyProduct {
                PlanCard(
                    product: monthly,
                    isSelected: selectedPlan == .monthly,
                    isRecommended: false,
                    onSelect: { selectedPlan = .monthly }
                )
            }
        }
    }
    
    // MARK: - Subscribe Button
    
    private var subscribeButton: some View {
        Button(action: {
            Task {
                let product: Product?
                switch selectedPlan {
                case .monthly:
                    product = subscriptionManager.monthlyProduct
                case .yearly:
                    product = subscriptionManager.yearlyProduct
                }
                
                if let product = product {
                    let success = await subscriptionManager.purchase(product)
                    if success {
                        onSubscribed()
                    }
                }
            }
        }) {
            Text("立即订阅")
                .font(AppFonts.cuteButton)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                        .fill(AppColors.primary)
                )
                .shadow(color: AppColors.primaryDepth, radius: 0, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(subscriptionManager.isLoading)
    }
    
    // MARK: - Restore Button
    
    private var restoreButton: some View {
        Button(action: {
            Task {
                let success = await subscriptionManager.restorePurchases()
                if success && subscriptionManager.hasAccess {
                    onSubscribed()
                }
            }
        }) {
            Text("恢复购买")
                .font(AppFonts.small)
                .foregroundStyle(AppColors.primary)
                .underline()
        }
        .buttonStyle(.plain)
        .disabled(subscriptionManager.isLoading)
    }
    
    // MARK: - Terms Section
    
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("订阅将自动续订，可随时在设置中取消")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textMedium)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button(action: {
                    if let url = URL(string: "https://www.gaiaforall.com/diandian/terms/") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("使用条款")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.purple)
                        .underline()
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    if let url = URL(string: "https://www.gaiaforall.com/diandian/privacy/") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("隐私政策")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.purple)
                        .underline()
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(AppColors.primary)
                .frame(width: 24)
            
            Text(text)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textBlack)
            
            Spacer()
        }
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let product: Product
    let isSelected: Bool
    let isRecommended: Bool
    let onSelect: () -> Void
    
    private var isYearly: Bool {
        product.id == SubscriptionProductID.yearly.rawValue
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? AppColors.primary : AppColors.textLight, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 14, height: 14)
                    }
                }
                
                // Plan info
                VStack(alignment: .leading, spacing: 4) {
                    if isRecommended {
                        Text("推荐")
                            .font(AppFonts.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(AppColors.accentCoral)
                            )
                    }
                    
                    Text(isYearly ? "年度会员" : "月度会员")
                        .font(AppFonts.subtitle)
                        .foregroundStyle(AppColors.textBlack)
                    
                    if isYearly {
                        Text("每月仅 ¥7.3，省59%")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textMedium)
                    }
                }
                
                Spacer()
                
                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(AppFonts.subtitle)
                        .foregroundStyle(AppColors.textBlack)
                    
                    Text(isYearly ? "/年" : "/月")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textMedium)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                    .fill(AppColors.bgCream)
                    .overlay(
                        RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                            .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
                    )
            )
            .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Subscription - Trial Active") {
    SubscriptionView(
        onSubscribed: { },
        onClose: { }
    )
}

#Preview("Subscription - Trial Expired") {
    SubscriptionView(
        onSubscribed: { },
        onClose: nil
    )
}
