import SwiftUI

public struct PrimaryButtonStyle: ButtonStyle {
    public enum Variant {
        case filled
        case outlined
    }

    private let variant: Variant
    private let cornerRadius: CGFloat
    private let horizontalPadding: CGFloat
    private let verticalPadding: CGFloat

    public init(
        variant: Variant = .filled,
        cornerRadius: CGFloat = 60,
        horizontalPadding: CGFloat = 24,
        verticalPadding: CGFloat = 18
    ) {
        self.variant = variant
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.body)
            .foregroundStyle(foregroundColor(isPressed: configuration.isPressed))
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity)
            .background(backgroundShape(isPressed: configuration.isPressed))
            .overlay(border)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }

    @ViewBuilder
    private func backgroundShape(isPressed: Bool) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(backgroundColor(isPressed: isPressed))
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        switch variant {
        case .filled:
            return AppColors.purple.opacity(isPressed ? 0.85 : 1)
        case .outlined:
            return Color.white.opacity(isPressed ? 0.95 : 1)
        }
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(borderColor, lineWidth: borderWidth)
    }

    private var borderWidth: CGFloat {
        switch variant {
        case .filled:
            return 0
        case .outlined:
            return 2
        }
    }

    private var borderColor: Color {
        switch variant {
        case .filled:
            return .clear
        case .outlined:
            return AppColors.purple
        }
    }

    private func foregroundColor(isPressed: Bool) -> Color {
        switch variant {
        case .filled:
            return Color.white.opacity(isPressed ? 0.85 : 1)
        case .outlined:
            return AppColors.purple.opacity(isPressed ? 0.85 : 1)
        }
    }
}

public extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primaryFilled: PrimaryButtonStyle { .init(variant: .filled) }
    static var primaryOutlined: PrimaryButtonStyle { .init(variant: .outlined) }
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
