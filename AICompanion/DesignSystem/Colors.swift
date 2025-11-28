import SwiftUI

// MARK: - Finch-Inspired Design System Colors
// A warm, gender-neutral palette with Duolingo-style 3D buttons
// Primary: Sage Green | Secondary: Light Sage | Accent: Warm Gold, Coral, Purple
public enum AppColors {
    
    // MARK: - Primary Colors (Finch-Inspired)
    public static let primary = Color(hex: "C7A4DF")        // Sage green - main accent
    public static let secondary = Color(hex: "7EB5A6")      // Light sage - secondary
    public static let tertiary = Color(hex: "F1A522")       // Warm gold - highlights    
    
    // MARK: - Accent Colors
    public static let accentBlue = Color(hex: "6BA3BE")     // Calm teal-blue
    public static let accentCoral = Color(hex: "E07A5F")    // Warm coral (alerts, energy)
    public static let accentPurple = Color(hex: "9B8EC4")   // Soft purple (fortune/mystical)
    public static let accentGreen = Color(hex: "14ce75")    // Same as primary
    public static let accentYellow = Color(hex: "FFF9C4")   // Same as tertiary
    public static let accentRed = Color(hex: "E07A5F")      // Same as coral
    
    // MARK: - Button Depth Colors (for 3D effect)
    public static let primaryDepth = Color(hex: "A080B8")   // Darker purple for button bottom (matches primary)
    public static let secondaryDepth = Color(hex: "6A9A8E") // Darker light sage
    public static let blueDepth = Color(hex: "5A8FA6")      // Darker blue for button bottom
    public static let coralDepth = Color(hex: "C4624D")     // Darker coral for button bottom
    public static let purpleDepth = Color(hex: "7A6FA0")    // Darker purple for button bottom
    
    // MARK: - Text Colors
    public static let textDark = Color(hex: "2D3436")       // Dark gray (not pure black)
    public static let textMedium = Color(hex: "636E72")     // Medium gray
    public static let textLight = Color(hex: "B2BEC3")      // Light gray
    public static let textBlack = textDark                  // Alias
    
    // MARK: - Background Colors
    // public static let bgCream = Color(hex: "FAF7F2")        // Warm cream background
    public static let bgCream = Color(hex: "F9E3E0")        // Warm cream background
    // public static let bgSageLight = Color(hex: "F0F5F3")    // Very light sage tint
    public static let bgSageLight = Color(hex: "F0CBF4")    // Very light sage tint
    public static let bgWarmLight = Color(hex: "FDF9F3")    // Warm off-white
    public static let cardWhite = Color.white               // Pure white for cards
    
    // MARK: - Legacy Background Aliases
    public static let bgPinkLight = bgSageLight             // Renamed for compatibility
    public static let bgLavenderLight = Color(hex: "F4F2F8") // Light purple tint
    public static let bgMintLight = bgSageLight
    
    // MARK: - Semantic Colors
    public static let purple = accentPurple
    public static let neutralGray = textMedium
    public static let white = bgCream
    public static let gold = tertiary
    public static let lightRed = Color(hex: "FCF0F0")
    
    // MARK: - Legacy Color Aliases (for backward compatibility)
    public static let cutePink = primary                    // Now sage green
    public static let cuteLavender = Color(hex: "C8B8D8")   // Soft lavender    
    public static let cutePeach = Color(hex: "F8E8D8")      // Warm cream        
    public static let cuteCoral = accentCoral
    public static let lavender = cuteLavender    
    public static let jade = Color(hex: "7EB5A6")  
    
    // MARK: - Gradient Backgrounds
    public static let gradientBackground = LinearGradient(
        colors: [bgCream, bgSageLight],
        startPoint: .top,
        endPoint: .bottom
    )
    
    public static let gradientBackgroundColor = bgCream
    
    public static let fortunePurpleGradient = LinearGradient(
        colors: [accentPurple, Color(hex: "B8A8D8")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Element colors (Five Elements)
    public static let elementGold = tertiary
    public static let elementWood = primary
    public static let elementWater = accentBlue
    public static let elementFire = accentCoral
    public static let elementEarth = Color(hex: "B8A898")
    
    // MARK: - Shadow Color
    public static let shadowColor = Color(hex: "2D3436").opacity(0.12)
    
    // MARK: - Neobrutalism Compatibility
    public static let neoBlack = textDark
    public static let neoWhite = bgCream
    public static let neoPurple = accentPurple
    public static let neoYellow = tertiary
    public static let neoPink = primary
    public static let neoBlue = accentBlue
    public static let neoGreen = primary
    public static let neoRed = accentCoral
    public static let neoOrange = tertiary
    public static let bgLavender = cuteLavender
    public static let bgMint = secondary
    public static let bgPeach = cutePeach
}

public extension Color {
    init(hex: String, opacity: Double = 1) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let r, g, b: UInt64
        switch sanitized.count {
        case 6:
            (r, g, b) = ((value & 0xFF0000) >> 16, (value & 0x00FF00) >> 8, value & 0x0000FF)
        case 3:
            let digits = (
                (value & 0xF00) >> 8,
                (value & 0x0F0) >> 4,
                value & 0x00F
            )
            (r, g, b) = (digits.0 * 17, digits.1 * 17, digits.2 * 17)
        default:
            (r, g, b) = (0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: opacity
        )
    }
}
