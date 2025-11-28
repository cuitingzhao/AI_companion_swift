import SwiftUI
import Combine

// MARK: - Cute Clean Loading Indicator with Gentle Animation
public struct ChatBubbleLoadingIndicator: View {
    @Binding private var isActive: Bool
    private let subtitle: String?
    @State private var dotsStep: Int = 0
    @State private var glowOpacity: CGFloat = 0.3

    public init(isActive: Binding<Bool>, subtitle: String? = nil) {
        self._isActive = isActive
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Cute Clean: Gentle floating dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(AppColors.cutePink)
                            .frame(width: 8, height: 8)
                            .offset(y: dotsStep % 3 == index ? -4 : 0)
                            .animation(
                                .easeInOut(duration: 0.4),
                                value: dotsStep
                            )
                    }
                }

                Text("思考中")
                    .font(AppFonts.cuteLabel)
                    .foregroundStyle(AppColors.textMedium)
            }

            if let subtitle {
                Text(subtitle)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textLight)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(AppColors.bgCream)
        .cornerRadius(CuteClean.radiusMedium)
        .shadow(
            color: AppColors.cutePink.opacity(glowOpacity),
            radius: 12,
            x: 0,
            y: 4
        )
        .onAppear {
            dotsStep = 0
            startGlowAnimation()
        }
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            guard isActive else { return }
            dotsStep += 1
        }
    }
    
    private func startGlowAnimation() {
        withAnimation(
            .easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
        ) {
            glowOpacity = 0.5
        }
    }
}
