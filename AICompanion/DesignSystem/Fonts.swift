import SwiftUI

// MARK: - Cute Clean Typography
// Rounded, friendly fonts that feel warm and approachable
public enum AppFonts {
    // MARK: - Primary Font Scale (Rounded Design)
    public static let title = Font.system(size: 32, weight: .semibold, design: .rounded)
    public static let subtitle = Font.system(size: 24, weight: .semibold, design: .rounded)
    public static let large = Font.system(size: 20, weight: .semibold, design: .rounded)
    public static let body = Font.system(size: 16, weight: .regular, design: .rounded)
    public static let small = Font.system(size: 14, weight: .regular, design: .rounded)
    public static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
    
    // MARK: - Cute Clean Specific Styles
    public static let cuteHeadline = Font.system(size: 22, weight: .semibold, design: .rounded)
    public static let cuteButton = Font.system(size: 16, weight: .semibold, design: .rounded)
    public static let cuteLabel = Font.system(size: 14, weight: .medium, design: .rounded)
    public static let cuteInput = Font.system(size: 16, weight: .regular, design: .rounded)
    
    // MARK: - Neobrutalism Compatibility (mapped to cute styles)
    public static let neoHeadline = cuteHeadline
    public static let neoButton = cuteButton
    public static let neoLabel = cuteLabel
    public static let neoInput = cuteInput
}
