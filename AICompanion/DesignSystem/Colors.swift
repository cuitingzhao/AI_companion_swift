import SwiftUI

public enum AppColors {
    public static let gradientBackground = RadialGradient(
        gradient: Gradient(colors: [
            Color(hex: "9FE3E0"),
            Color(hex: "F0CBF4")
        ]),
        center: .center,
        startRadius: 0,
        endRadius: 400
    )

    public static let fortunePurpleGradient = RadialGradient(
        gradient: Gradient(colors: [            
            AppColors.purple.opacity(0.8),
            AppColors.purple
        ]),
        center: .center,
        startRadius: 0,
        endRadius: 280
    )

    public static let purple = Color(hex: "5E17EB")
    public static let lavender: Color = Color(hex: "C7A4DF")
    public static let textBlack = Color(hex: "5C5C5C")
    public static let accentYellow = Color(hex: "F4CD0B")
    public static let accentGreen = Color(hex: "14CE75")
    public static let accentBlue = Color(hex: "4A90E2")
    public static let accentRed = Color(hex: "FF5A5F")
    public static let accentBrown = Color(hex: "8B572A")
    public static let neutralGray = Color(hex: "A6A6A6")
    public static let jade = Color(hex: "ACCFC3")
    public static let white = Color(hex: "FFFFFF")
    public static let gold = Color(hex: "F1A522")
    public static let lightRed = Color(hex: "F9E3E0")

    // Element colors
    public static let elementGold = accentYellow
    public static let elementWood = accentGreen
    public static let elementWater = accentBlue
    public static let elementFire = accentRed
    public static let elementEarth = accentBrown
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
