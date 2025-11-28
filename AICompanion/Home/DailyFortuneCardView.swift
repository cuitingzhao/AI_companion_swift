import SwiftUI

// MARK: - Finch-Inspired Daily Fortune Card
struct DailyFortuneCardView: View {
    let isLoading: Bool
    let fortune: DailyFortuneResponse?
    let errorText: String?
    let onDismiss: () -> Void

    @State private var isSpinning: Bool = false
    @State private var glowIntensity: CGFloat = 0.3

    var body: some View {
        ZStack {
            // Finch-inspired: Purple gradient for mystical feel
            RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                .fill(
                    LinearGradient(
                        colors: [AppColors.bgCream, AppColors.bgCream.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: AppColors.purpleDepth.opacity(glowIntensity),
                    radius: 16,
                    x: 0,
                    y: 6
                )

            // Content
            VStack(spacing: 16) {
                if isLoading {
                    Image("fortune_wheel_small")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .rotationEffect(Angle.degrees(isSpinning ? 360 : 0))
                        .animation(.linear(duration: 2.0).repeatForever(autoreverses: false), value: isSpinning)

                    Text("正在为你推算今日运势，请稍候…")
                        .font(AppFonts.body)
                        .foregroundStyle(.white)
                } else if let fortune {
                    // 结果态：主内容（标题 + symbol + 利/忌）在卡片中部
                    VStack(spacing: 12) {
                        Spacer(minLength: 0)

                        VStack(spacing: 16) {
                            Text("今日签")
                                .font(AppFonts.cuteLabel)
                                .foregroundStyle(AppColors.textBlack)

                            ZStack {
                                // symbol 背景颜色根据运势等级变化 - softer colors
                                Circle()
                                    .fill(symbolBackgroundColor(for: fortune.fortuneLevel ?? ""))
                                    .frame(width: 120, height: 120)
                                    .shadow(color: symbolBackgroundColor(for: fortune.fortuneLevel ?? "").opacity(0.5), radius: 12)

                                Circle()
                                    .stroke(.white.opacity(0.6), lineWidth: 2)
                                    .frame(width: 104, height: 104)

                                Text(fortune.fortuneLevel ?? "")
                                    .font(AppFonts.title)
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                // Soft divider
                                Rectangle()
                                    .fill(.white.opacity(0.3))
                                    .frame(height: 1)

                                // 利：部分
                                HStack(alignment: .top, spacing: 8) {                                    
                                    Text("✅")
                                        .font(AppFonts.small)

                                    Text(fortune.good ?? "")
                                        .font(AppFonts.small)
                                        .foregroundStyle(AppColors.textBlack)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }.padding(.horizontal, 6)

                                Rectangle()
                                    .fill(.white.opacity(0.3))
                                    .frame(height: 1)

                                // 忌：部分
                                HStack(alignment: .top, spacing: 8) {
                                    Text("🚫")
                                        .font(AppFonts.small)

                                    Text(fortune.avoid ?? "")
                                        .font(AppFonts.small)
                                        .foregroundStyle(AppColors.textBlack)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }.padding(.horizontal, 6)

                                Rectangle()
                                    .fill(.white.opacity(0.3))
                                    .frame(height: 1)
                            }
                        }

                        Spacer(minLength: 0)
                        
                        // Finch 3D Close button
                        Button(action: onDismiss) {
                            Text("知道了")
                                .font(AppFonts.cuteButton)
                                .foregroundStyle(AppColors.accentPurple)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                                            .fill(Color.white.opacity(0.7))
                                            .offset(y: 3)
                                        RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                                            .fill(Color.white.opacity(0.95))
                                    }
                                )
                        }
                        .buttonStyle(.plain)
                    }
                } else if let errorText {
                    Text(errorText)
                        .font(AppFonts.body)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                } else {
                    Text("暂时无法获取今日运势，请稍后再试。")
                        .font(AppFonts.body)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: 320)
        .aspectRatio(2/3, contentMode: .fit)
        .onAppear {
            if isLoading {
                isSpinning = true
            }
            // Gentle glow animation
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowIntensity = 0.5
            }
        }
    }

    private func symbolBackgroundColor(for level: String) -> Color {
        switch level {
        case "吉":
            return AppColors.accentYellow  // Darker gold for better contrast with white text
        case "平":
            return AppColors.accentGreen  // Darker mint for better contrast
        case "凶":
            return AppColors.textMedium  // Soft gray instead of black
        default:
            return .white.opacity(0.9)
        }
    }
}
