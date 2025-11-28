import SwiftUI

// MARK: - Finch-Inspired View Modifiers
// Duolingo-style 3D buttons with warm, gender-neutral styling

// MARK: - Rounded Corner Shape (for selective corner rounding)
public struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    public func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

public extension View {
    /// Applies cute clean card styling with soft shadow and rounded corners
    func cuteCard(
        backgroundColor: Color = AppColors.bgCream,
        cornerRadius: CGFloat = 20,
        shadowRadius: CGFloat = 12
    ) -> some View {
        self
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: AppColors.shadowColor, radius: shadowRadius, x: 0, y: 4)
    }
    
    /// Applies cute clean button styling with gentle press animation
    func cuteButton(
        backgroundColor: Color = AppColors.cutePink,
        isPressed: Bool = false
    ) -> some View {
        self
            .background(backgroundColor)
            .cornerRadius(CuteClean.radiusMedium)
            .shadow(
                color: AppColors.shadowColor,
                radius: isPressed ? 4 : 8,
                x: 0,
                y: isPressed ? 2 : 4
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
    }
    
    /// Applies cute clean input field styling
    func cuteInput(
        borderColor: Color = AppColors.cutePink.opacity(0.3),
        backgroundColor: Color = AppColors.bgCream
    ) -> some View {
        self
            .background(backgroundColor)
            .cornerRadius(CuteClean.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
    }
    
    /// Applies subtle border (cute style)
    func cuteBorder(
        color: Color = AppColors.cutePink.opacity(0.3),
        width: CGFloat = 1,
        cornerRadius: CGFloat = 16
    ) -> some View {
        self
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color, lineWidth: width)
            )
    }
    
    /// Applies soft shadow
    func cuteShadow(
        color: Color = AppColors.shadowColor,
        radius: CGFloat = 8,
        y: CGFloat = 4
    ) -> some View {
        self.shadow(color: color, radius: radius, x: 0, y: y)
    }
    
    // MARK: - Neobrutalism Compatibility (mapped to cute styles)
    func neoBrutalCard(
        backgroundColor: Color = AppColors.bgCream,
        borderColor: Color = AppColors.cutePink.opacity(0.2),
        borderWidth: CGFloat = 1,
        cornerRadius: CGFloat = 20,
        shadowOffset: CGFloat = 4
    ) -> some View {
        self.cuteCard(backgroundColor: backgroundColor, cornerRadius: cornerRadius)
    }
    
    func neoBrutalButton(
        backgroundColor: Color = AppColors.cutePink,
        isPressed: Bool = false
    ) -> some View {
        self.cuteButton(backgroundColor: backgroundColor, isPressed: isPressed)
    }
    
    func neoBrutalInput(
        borderColor: Color = AppColors.cutePink.opacity(0.3),
        backgroundColor: Color = AppColors.bgCream
    ) -> some View {
        self.cuteInput(borderColor: borderColor, backgroundColor: backgroundColor)
    }
    
    func neoBrutalBorder(
        color: Color = AppColors.cutePink.opacity(0.3),
        width: CGFloat = 1,
        cornerRadius: CGFloat = 16
    ) -> some View {
        self.cuteBorder(color: color, width: width, cornerRadius: cornerRadius)
    }
    
    func neoShadow(
        color: Color = AppColors.shadowColor,
        x: CGFloat = 0,
        y: CGFloat = 4
    ) -> some View {
        self.cuteShadow(color: color, radius: 8, y: y)
    }
}

// MARK: - Finch Design Constants
public enum CuteClean {
    // Corner radii (substantial but friendly)
    public static let radiusSmall: CGFloat = 10
    public static let radiusMedium: CGFloat = 12
    public static let radiusLarge: CGFloat = 16
    public static let radiusXLarge: CGFloat = 20
    
    // Button depth (for 3D effect)
    public static let buttonDepth: CGFloat = 6
    public static let buttonDepthPressed: CGFloat = 2
    
    // Shadow settings
    public static let shadowLight: CGFloat = 4
    public static let shadowMedium: CGFloat = 8
    public static let shadowLarge: CGFloat = 12
    
    // Animation durations
    public static let animationQuick: Double = 0.1
    public static let animationNormal: Double = 0.2
    public static let animationSlow: Double = 0.3
}

// MARK: - Neobrutalism Constants (Compatibility - mapped to CuteClean)
public enum NeoBrutal {
    public static let borderThin: CGFloat = 1
    public static let borderNormal: CGFloat = 1
    public static let borderThick: CGFloat = 1.5
    
    public static let radiusSmall: CGFloat = CuteClean.radiusSmall
    public static let radiusMedium: CGFloat = CuteClean.radiusMedium
    public static let radiusLarge: CGFloat = CuteClean.radiusLarge
    
    public static let shadowSmall: CGFloat = CuteClean.shadowLight
    public static let shadowMedium: CGFloat = CuteClean.shadowMedium
    public static let shadowLarge: CGFloat = CuteClean.shadowLarge
    
    public static let animationQuick: Double = CuteClean.animationQuick
    public static let animationNormal: Double = CuteClean.animationNormal
}

// MARK: - Finch 3D Primary Button Style (Duolingo-inspired)
public struct CuteButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let depthColor: Color
    let foregroundColor: Color
    
    public init(
        backgroundColor: Color = AppColors.primary,
        depthColor: Color = AppColors.primaryDepth,
        foregroundColor: Color = .white
    ) {
        self.backgroundColor = backgroundColor
        self.depthColor = depthColor
        self.foregroundColor = foregroundColor
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let depth = isPressed ? CuteClean.buttonDepthPressed : CuteClean.buttonDepth
        let offset = isPressed ? CuteClean.buttonDepth - CuteClean.buttonDepthPressed : 0
        
        configuration.label
            .font(AppFonts.cuteButton)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    // Bottom depth layer (3D effect)
                    RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                        .fill(depthColor)
                        .offset(y: depth)
                    
                    // Main button face
                    RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                        .fill(backgroundColor)
                        .offset(y: offset)
                }
            )
            .offset(y: offset)
            .animation(.easeOut(duration: CuteClean.animationQuick), value: isPressed)
    }
}

// MARK: - Finch 3D Button Style (Generic)
public struct Finch3DButtonStyle: ButtonStyle {
    let color: Color
    let depthColor: Color
    
    public init(color: Color, depthColor: Color) {
        self.color = color
        self.depthColor = depthColor
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let depth = isPressed ? CuteClean.buttonDepthPressed : CuteClean.buttonDepth
        let offset = isPressed ? CuteClean.buttonDepth - CuteClean.buttonDepthPressed : 0
        
        configuration.label
            .font(AppFonts.cuteButton)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                        .fill(depthColor)
                        .offset(y: depth)
                    
                    RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                        .fill(color)
                        .offset(y: offset)
                }
            )
            .offset(y: offset)
            .animation(.easeOut(duration: CuteClean.animationQuick), value: isPressed)
    }
}

// MARK: - Finch 3D Secondary Button Style (Outline with depth)
public struct CuteSecondaryButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let depth: CGFloat = isPressed ? 1 : 3
        let offset: CGFloat = isPressed ? 2 : 0
        
        configuration.label
            .font(AppFonts.cuteButton)
            .foregroundColor(AppColors.primary)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    // Depth layer (subtle)
                    RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                        .fill(AppColors.primary.opacity(0.3))
                        .offset(y: depth)
                    
                    // Main button face
                    RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                        .fill(AppColors.cardWhite)
                        .overlay(
                            RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                                .stroke(AppColors.primary, lineWidth: 2)
                        )
                        .offset(y: offset)
                }
            )
            .offset(y: offset)
            .animation(.easeOut(duration: CuteClean.animationQuick), value: isPressed)
    }
}

// MARK: - Neobrutalism Button Styles (Compatibility - mapped to Cute)
public typealias NeoBrutalButtonStyle = CuteButtonStyle
public typealias NeoBrutalSecondaryButtonStyle = CuteSecondaryButtonStyle

// MARK: - Button Style Extensions
public extension ButtonStyle where Self == CuteButtonStyle {
    static var cute: CuteButtonStyle { .init() }
    static var finch: CuteButtonStyle { .init() }
    static func cute(bg: Color, depth: Color, fg: Color = .white) -> CuteButtonStyle {
        .init(backgroundColor: bg, depthColor: depth, foregroundColor: fg)
    }
    static var neoBrutal: CuteButtonStyle { .init() }
    static func neoBrutal(bg: Color, fg: Color = .white) -> CuteButtonStyle {
        .init(backgroundColor: bg, depthColor: AppColors.primaryDepth, foregroundColor: fg)
    }
}

public extension ButtonStyle where Self == Finch3DButtonStyle {
    static func finch3D(color: Color, depth: Color) -> Finch3DButtonStyle {
        .init(color: color, depthColor: depth)
    }
    
    // Preset button styles
    static var finchPrimary: Finch3DButtonStyle {
        .init(color: AppColors.primary, depthColor: AppColors.primaryDepth)
    }
    static var finchCoral: Finch3DButtonStyle {
        .init(color: AppColors.accentCoral, depthColor: AppColors.coralDepth)
    }
    static var finchBlue: Finch3DButtonStyle {
        .init(color: AppColors.accentBlue, depthColor: AppColors.blueDepth)
    }
    static var finchPurple: Finch3DButtonStyle {
        .init(color: AppColors.accentPurple, depthColor: AppColors.purpleDepth)
    }
}

public extension ButtonStyle where Self == CuteSecondaryButtonStyle {
    static var cuteSecondary: CuteSecondaryButtonStyle { .init() }
    static var neoBrutalSecondary: CuteSecondaryButtonStyle { .init() }
}

// MARK: - Finch-Inspired Animations
public extension Animation {
    /// Snappy animation for 3D button presses
    static var finchPress: Animation {
        .easeOut(duration: 0.1)
    }
    
    /// Gentle spring animation for bouncy effects
    static var finchBounce: Animation {
        .spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)
    }
    
    /// Quick animation for micro-interactions
    static var finchQuick: Animation {
        .easeOut(duration: 0.12)
    }
    
    /// Smooth animation for transitions
    static var finchSmooth: Animation {
        .easeInOut(duration: 0.25)
    }
    
    // Legacy compatibility
    static var cuteBounce: Animation { finchBounce }
    static var cuteQuick: Animation { finchQuick }
    static var cuteDreamy: Animation { finchSmooth }
    static var neoBounce: Animation { finchBounce }
    static var neoQuick: Animation { finchQuick }
    static var neoPlayful: Animation { finchSmooth }
}

// MARK: - Finch 3D Tap Effect Modifier
public struct Finch3DTapEffect: ViewModifier {
    @State private var isPressed = false
    let depth: CGFloat
    let action: () -> Void
    
    public init(depth: CGFloat = 4, action: @escaping () -> Void) {
        self.depth = depth
        self.action = action
    }
    
    public func body(content: Content) -> some View {
        content
            .offset(y: isPressed ? depth * 0.75 : 0)
            .animation(.finchPress, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in
                        isPressed = false
                        action()
                    }
            )
    }
}

// MARK: - Legacy Tap Effect (Scale-based)
public struct CuteTapEffect: ViewModifier {
    @State private var isPressed = false
    let action: () -> Void
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.finchQuick, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in
                        isPressed = false
                        action()
                    }
            )
    }
}

// Compatibility aliases
public typealias NeoTapEffect = CuteTapEffect

public extension View {
    /// Adds a Finch-style 3D tap effect with depth animation
    func finch3DTapEffect(depth: CGFloat = 4, action: @escaping () -> Void) -> some View {
        modifier(Finch3DTapEffect(depth: depth, action: action))
    }
    
    /// Adds a cute tap effect with gentle scale animation
    func cuteTapEffect(action: @escaping () -> Void) -> some View {
        modifier(CuteTapEffect(action: action))
    }
    
    /// Adds a gentle pulse animation (for attention)
    func finchPulse(_ isActive: Bool) -> some View {
        self.scaleEffect(isActive ? 1.02 : 1.0)
            .animation(
                isActive ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true) : .default,
                value: isActive
            )
    }
    
    /// Legacy pulse animation
    func cutePulse(_ isActive: Bool) -> some View {
        finchPulse(isActive)
    }
    
    /// Adds a soft glow effect
    func finchGlow(_ isActive: Bool, color: Color = AppColors.primary) -> some View {
        self.shadow(
            color: isActive ? color.opacity(0.4) : .clear,
            radius: isActive ? 10 : 0
        )
        .animation(.finchSmooth, value: isActive)
    }
    
    /// Legacy glow effect
    func cuteGlow(_ isActive: Bool, color: Color = AppColors.primary) -> some View {
        finchGlow(isActive, color: color)
    }
    
    /// Adds a gentle floating animation (for decorative elements)
    func finchFloat(_ isActive: Bool) -> some View {
        self.offset(y: isActive ? -3 : 0)
            .animation(
                isActive ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true) : .default,
                value: isActive
            )
    }
    
    /// Legacy float animation
    func cuteFloat(_ isActive: Bool) -> some View {
        self.offset(y: isActive ? -4 : 0)
            .animation(
                isActive ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true) : .default,
                value: isActive
            )
    }
    
    /// Adds a soft breathing animation (for loading states)
    func cuteBreathing(_ isActive: Bool) -> some View {
        self.opacity(isActive ? 0.6 : 1.0)
            .animation(
                isActive ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
                value: isActive
            )
    }
    
    /// Adds a sparkle effect (for success states)
    func cuteSparkle(_ isActive: Bool) -> some View {
        self
            .scaleEffect(isActive ? 1.1 : 1.0)
            .opacity(isActive ? 1.0 : 0.8)
            .animation(
                isActive ? .spring(response: 0.4, dampingFraction: 0.5) : .default,
                value: isActive
            )
    }
    
    /// Adds a gentle shake animation (for errors - but cute!)
    func cuteShake(_ isActive: Bool) -> some View {
        self.offset(x: isActive ? 3 : 0)
            .animation(
                isActive ? .easeInOut(duration: 0.1).repeatCount(3, autoreverses: true) : .default,
                value: isActive
            )
    }
    
    // Neobrutalism compatibility
    func neoTapEffect(action: @escaping () -> Void) -> some View {
        cuteTapEffect(action: action)
    }
    
    func neoWiggle(_ isActive: Bool) -> some View {
        cutePulse(isActive)  // Map wiggle to pulse for softer effect
    }
    
    func neoPulse(_ isActive: Bool) -> some View {
        cutePulse(isActive)
    }
}

// MARK: - Cute Clean Shimmer Effect (for loading)
public struct CuteShimmer: ViewModifier {
    @State private var phase: CGFloat = 0
    let isActive: Bool
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isActive {
                        LinearGradient(
                            colors: [
                                .clear,
                                AppColors.cutePink.opacity(0.3),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                        .animation(
                            .linear(duration: 1.5).repeatForever(autoreverses: false),
                            value: phase
                        )
                    }
                }
                .mask(content)
            )
            .onAppear {
                if isActive {
                    phase = 1
                }
            }
    }
}

public extension View {
    /// Adds a cute shimmer loading effect
    func cuteShimmer(_ isActive: Bool) -> some View {
        modifier(CuteShimmer(isActive: isActive))
    }
}

// MARK: - Cute Clean Card Hover Effect
public struct CuteHoverEffect: ViewModifier {
    @State private var isHovered = false
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .shadow(
                color: isHovered ? AppColors.cutePink.opacity(0.2) : AppColors.shadowColor,
                radius: isHovered ? 16 : 8,
                x: 0,
                y: isHovered ? 6 : 4
            )
            .animation(.easeOut(duration: CuteClean.animationQuick), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

public extension View {
    /// Adds a cute hover effect for cards (macOS/iPadOS)
    func cuteHover() -> some View {
        modifier(CuteHoverEffect())
    }
}
