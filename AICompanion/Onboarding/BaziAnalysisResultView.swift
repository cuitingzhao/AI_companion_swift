import SwiftUI

public struct BaziAnalysisResultView: View {
    @ObservedObject private var state: OnboardingState
    private let onStart: () -> Void
    private let onSkip: () -> Void
    @State private var animatePillars = false
    @State private var isBreathing = false

    public init(state: OnboardingState, onStart: @escaping () -> Void = {}, onSkip: @escaping () -> Void = {}) {
        self.state = state
        self.onStart = onStart
        self.onSkip = onSkip
    }

    private var response: OnboardingSubmitResponse? {
        state.lastSubmitResponse
    }

    private var bazi: BaziData? {
        response?.bazi
    }

    private var analysis: BaziAnalysisResult? {
        response?.baziAnalysis
    }

    private var dayHeavenlyStem: String {
        bazi?.dayGanzhi.heavenlyStem ?? ""
    }

    private var partnerName: String {
        guard let element = elementForStem(dayHeavenlyStem) else { return "" }
        return "\(element)宝"
    }

    private var dayMasterElement: String? {
        elementForStem(dayHeavenlyStem)
    }

    private var dayMasterLabel: String {
        guard let element = dayMasterElement else { return "" }
        return "「\(dayHeavenlyStem)\(element)」"
    }

    private var dayMasterColor: Color {
        guard let element = dayMasterElement else { return AppColors.textBlack }
        return color(forElement: element)
    }

    private func elementForStem(_ stem: String) -> String? {
        switch stem {
        case "甲", "乙":
            return "木"
        case "丙", "丁":
            return "火"
        case "戊", "己":
            return "土"
        case "庚", "辛":
            return "金"
        case "壬", "癸":
            return "水"
        default:
            return nil
        }
    }

    private func elementForBranch(_ branch: String) -> String? {
        switch branch {
        case "寅", "卯":
            return "木"
        case "巳", "午":
            return "火"
        case "申", "酉":
            return "金"
        case "子", "亥":
            return "水"
        case "丑", "辰", "未", "戌":
            return "土"
        default:
            return nil
        }
    }

    private func color(forElement element: String) -> Color {
        switch element {
        case "金":
            return AppColors.elementGold
        case "木":
            return AppColors.elementWood
        case "水":
            return AppColors.elementWater
        case "火":
            return AppColors.elementFire
        case "土":
            return AppColors.elementEarth
        default:
            return AppColors.textBlack
        }
    }

    private func colorForHeavenlyStem(_ stem: String) -> Color {
        if let element = elementForStem(stem) {
            return color(forElement: element)
        }
        return AppColors.textBlack
    }

    private func colorForEarthlyBranch(_ branch: String) -> Color {
        if let element = elementForBranch(branch) {
            return color(forElement: element)
        }
        return AppColors.textBlack
    }

    private func characterAnimation(index: Int) -> Animation {
        // 0...7 (4 pillars x 2 characters), small stagger between each
        let baseDelay = 0.05 * Double(index)
        return .easeOut(duration: 0.35).delay(baseDelay)
    }

    public var body: some View {
        OnboardingScaffold(
            // topSpacing: 80, 
            containerColor: .white.opacity(0.8),
            // isCentered: true,
            // verticalPadding: 48,
            header: { 
                VStack(spacing: 8) {                  
                    GIFImage(name: "winking")
                            .frame(width: 180, height: 100)}
         }) {
            VStack(spacing: 0) {
                Spacer()

                // Main content in the middle of the container
                VStack(spacing: 20) {
                    if let bazi {
                        // Day master label above the pillars with breathing effect
                        if !dayMasterLabel.isEmpty {
                            Text(dayMasterLabel)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(dayMasterColor)
                                .scaleEffect(isBreathing ? 1.05 : 1.0)
                                .opacity(isBreathing ? 1.0 : 0.85)
                                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isBreathing)
                        }

                        // Bazi pillars in container
                        let pillars: [Ganzhi] = [
                            bazi.yearGanzhi,
                            bazi.monthGanzhi,
                            bazi.dayGanzhi,
                            bazi.hourGanzhi
                        ]

                        HStack(spacing: 20) {
                            ForEach(0..<pillars.count, id: \.self) { index in
                                let pillar = pillars[index]
                                let stemIndex = index * 2
                                let branchIndex = index * 2 + 1

                                VStack(spacing: 6) {
                                    Text(pillar.heavenlyStem)
                                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                                        .foregroundStyle(colorForHeavenlyStem(pillar.heavenlyStem))
                                        .scaleEffect(animatePillars ? 1.0 : 0.9)
                                        .opacity(animatePillars ? 1 : 0.7)
                                        .animation(characterAnimation(index: stemIndex), value: animatePillars)

                                    Text(pillar.earthlyBranch)
                                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                                        .foregroundStyle(colorForEarthlyBranch(pillar.earthlyBranch))
                                        .scaleEffect(animatePillars ? 1 : 0.9)
                                        .opacity(animatePillars ? 1 : 0.7)
                                        .animation(characterAnimation(index: branchIndex), value: animatePillars)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppColors.primary.opacity(0.2))
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                    } else if let chartText = analysis?.chartText, !chartText.isEmpty {
                        Text(chartText)
                            .font(AppFonts.body)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(AppColors.textBlack)
                            .padding(.horizontal, 4)
                    } else {
                        Text("暂时无法展示八字详情，请稍后重试")
                            .font(AppFonts.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppColors.textBlack)
                    }

                    if !dayHeavenlyStem.isEmpty, !partnerName.isEmpty {
                        Text("根据你的八字，\n我初步推测了你的性格，\n能请你确认一下吗？")
                            .font(AppFonts.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppColors.textBlack)
                            .padding(.top, 8)
                    }
                }
                .onAppear {
                    // Trigger entrance animation for pillars
                    animatePillars = false
                    isBreathing = false
                    DispatchQueue.main.async {
                        animatePillars = true
                        isBreathing = true
                    }
                }

                Spacer()

                // Bottom CTA block with two buttons
                VStack(spacing: 12) {
                    SimpleButton("好的", variant: .filled, action: onStart)
                    SimpleButton("暂时跳过", variant: .outlined, action: onSkip)
                }
            }
        }
    }
}

#Preview {
    let state = OnboardingState()
    BaziAnalysisResultView(state: state)
}
