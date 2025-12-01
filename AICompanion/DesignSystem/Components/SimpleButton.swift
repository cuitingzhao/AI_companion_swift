import SwiftUI

/// A simple button with shadow effect, matching the onboarding flow style.
/// Supports filled (primary) and outlined variants.
public struct SimpleButton: View {
    public enum Variant {
        case filled
        case outlined
    }
    
    private let title: String
    private let variant: Variant
    private let isEnabled: Bool
    private let action: () -> Void
    
    public init(
        _ title: String,
        variant: Variant = .filled,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.isEnabled = isEnabled
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.cuteButton)
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: 280)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                        .fill(backgroundColor)
                )
                .overlay(
                    variant == .outlined ?
                    RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                        .stroke(AppColors.primary, lineWidth: 1.5)
                    : nil
                )
                .shadow(color: AppColors.shadowColor, radius: 6, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
    
    private var backgroundColor: Color {
        switch variant {
        case .filled:
            return isEnabled ? AppColors.primary : AppColors.primary.opacity(0.4)
        case .outlined:
            return .white
        }
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .filled:
            return .white
        case .outlined:
            return AppColors.primary
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SimpleButton("开始", variant: .filled, isEnabled: true) { }
        SimpleButton("开始", variant: .filled, isEnabled: false) { }
        SimpleButton("暂时跳过", variant: .outlined) { }
    }
    .padding()
    .background(AppColors.bgCream)
}
