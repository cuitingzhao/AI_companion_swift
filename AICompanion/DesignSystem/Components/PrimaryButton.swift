import SwiftUI

// MARK: - Finch-Inspired 3D Primary Button Style
public struct PrimaryButtonStyle: ButtonStyle {
    public enum Variant {
        case filled
        case outlined
    }

    private let variant: Variant
    private let color: Color
    private let depthColor: Color
    private let cornerRadius: CGFloat
    private let horizontalPadding: CGFloat
    private let verticalPadding: CGFloat

    public init(
        variant: Variant = .filled,
        color: Color = AppColors.primary,
        depthColor: Color = AppColors.primaryDepth,
        cornerRadius: CGFloat = CuteClean.radiusMedium,
        horizontalPadding: CGFloat = 24,
        verticalPadding: CGFloat = 14
    ) {
        self.variant = variant
        self.color = color
        self.depthColor = depthColor
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
    }

    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let depth = isPressed ? CuteClean.buttonDepthPressed : CuteClean.buttonDepth
        let offset = isPressed ? CuteClean.buttonDepth - CuteClean.buttonDepthPressed : 0
        
        configuration.label
            .font(AppFonts.cuteButton)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: 280)
            .background(
                ZStack {
                    // Bottom depth layer (3D effect)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(variant == .filled ? depthColor : color.opacity(0.3))
                        .offset(y: depth)
                    
                    // Main button face
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(backgroundColor)
                        .overlay(
                            variant == .outlined ?
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(color, lineWidth: 2) : nil
                        )
                        .offset(y: offset)
                }
            )
            .offset(y: offset)
            .animation(.easeOut(duration: CuteClean.animationQuick), value: isPressed)
    }

    private var backgroundColor: Color {
        switch variant {
        case .filled:
            return color
        case .outlined:
            return AppColors.cardWhite
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .filled:
            return .white
        case .outlined:
            return color
        }
    }
}

public extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primaryFilled: PrimaryButtonStyle { .init(variant: .filled) }
    static var primaryOutlined: PrimaryButtonStyle { .init(variant: .outlined) }
    
    // Finch color variants
    static var primaryCoral: PrimaryButtonStyle {
        .init(variant: .filled, color: AppColors.accentCoral, depthColor: AppColors.coralDepth)
    }
    static var primaryBlue: PrimaryButtonStyle {
        .init(variant: .filled, color: AppColors.accentBlue, depthColor: AppColors.blueDepth)
    }
    static var primaryPurple: PrimaryButtonStyle {
        .init(variant: .filled, color: AppColors.accentPurple, depthColor: AppColors.purpleDepth)
    }
}

public struct PrimaryButton<Label: View>: View {
    private let action: () -> Void
    private let label: () -> Label
    private let style: PrimaryButtonStyle

    public init(
        action: @escaping () -> Void,
        style: PrimaryButtonStyle = .init(),
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.action = action
        self.label = label
        self.style = style
    }

    public var body: some View {
        Button(action: action) {
            label()
        }
        .buttonStyle(style)
    }
}
