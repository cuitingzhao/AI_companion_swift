import SwiftUI

// MARK: - Splash View

/// Splash screen shown during initial app loading
struct SplashView: View {
    var body: some View {
        ZStack {
            // Background color matching app theme
            AppColors.accentYellow
                .ignoresSafeArea()
            
            // Center image + text together
            VStack(spacing: 24) {
                // Mascot GIF
                GIFImage(name: "looking")
                    .frame(width: 200, height: 200)
                
                // Loading text with accent on "点点"
                HStack(spacing: 0) {
                    Text("「")
                    Text("点点")
                        .foregroundStyle(AppColors.primary)
                        .font(AppFonts.subtitle)
                    Text("」是陪伴，也是目标搭子")
                }
                .font(AppFonts.subtitle)
                .foregroundStyle(AppColors.textMedium)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

#Preview {
    SplashView()
}
