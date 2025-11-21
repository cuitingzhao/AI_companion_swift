import SwiftUI

struct DailyFortuneCardView: View {
    let isLoading: Bool
    let fortune: DailyFortuneResponse?
    let errorText: String?

    @State private var isSpinning: Bool = false

    var body: some View {
        ZStack {
            // Outer container: purple gradient, no white border
            RoundedRectangle(cornerRadius: 0)
                .fill(AppColors.fortunePurpleGradient.opacity(0.9))
                .shadow(color: Color.black.opacity(0.2), radius: 18, x: 0, y: 10)

            // Inner container: inset with white border
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.white.opacity(0.95), lineWidth: 1.5)
                .padding(10)

            // Content
            VStack(spacing: 16) {
                if isLoading {
                    Image("fortune_wheel_small")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .rotationEffect(Angle.degrees(isSpinning ? 360 : 0))
                        .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: isSpinning)

                    Text("正在为你推算今日运势，请稍候…")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.white)
                } else if let fortune {
                    // 结果态：主内容（标题 + symbol + 利/忌）在卡片中部，reason 靠近底部
                    VStack(spacing: 12) {
                        Spacer(minLength: 0)

                        VStack(spacing: 16) {
                            Text("今日签")
                                .font(AppFonts.small)
                                .foregroundStyle(AppColors.white)

                            ZStack {
                                // symbol 背景颜色根据运势等级变化
                                Circle()
                                    .fill(symbolBackgroundColor(for: fortune.fortuneLevel))
                                    .frame(width: 120, height: 120)

                                Circle()
                                    .stroke(AppColors.white.opacity(0.9), lineWidth: 2)
                                    .frame(width: 104, height: 104)

                                Text(fortune.fortuneLevel)
                                    .font(AppFonts.large)
                                    .foregroundStyle(AppColors.white)
                                    .scaleEffect(1.5)
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Divider()
                                    .background(AppColors.white)

                                // 利：部分
                                HStack(alignment: .top, spacing: 8) {                                    
                                    Text("✅：")
                                        .font(AppFonts.small)
                                        .foregroundStyle(AppColors.white)

                                    Text(fortune.good)
                                        .font(AppFonts.small)
                                        .foregroundStyle(AppColors.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }.padding(.horizontal, 6)

                                Divider()
                                    .background(AppColors.white)

                                // 忌：部分
                                HStack(alignment: .top, spacing: 8) {
                                    Text("🚫：")
                                        .font(AppFonts.small)
                                        .foregroundStyle(AppColors.white)

                                    Text(fortune.avoid)
                                        .font(AppFonts.small)
                                        .foregroundStyle(AppColors.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }.padding(.horizontal, 6)

                                Divider()
                                    .background(AppColors.white)

                            }
                        }

                        Spacer(minLength: 0)

                        // if let reason = fortune.reason, !reason.isEmpty {
                        //     Text(reason)
                        //         .font(AppFonts.caption)
                        //         .foregroundStyle(AppColors.white.opacity(0.9))
                        //         .frame(maxWidth: .infinity, alignment: .leading)
                        // }
                    }
                } else if let errorText {
                    Text(errorText)
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.white)
                        .multilineTextAlignment(.center)
                } else {
                    Text("暂时无法获取今日运势，请稍后再试。")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.white)
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
        }
    }

    private func symbolBackgroundColor(for level: String) -> Color {
        switch level {
        case "吉":
            return AppColors.gold
        case "平":
            return AppColors.jade
        case "凶":
            return AppColors.textBlack
        default:
            return AppColors.white.opacity(0.9)
        }
    }
}
