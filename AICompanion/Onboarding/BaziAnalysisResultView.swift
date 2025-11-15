import SwiftUI

public struct BaziAnalysisResultView: View {
    @ObservedObject private var state: OnboardingState
    private let onNext: () -> Void
    @State private var animatePillars = false
    @State private var isDayMasterHighlighted = false

    public init(state: OnboardingState, onNext: @escaping () -> Void = {}) {
        self.state = state
        self.onNext = onNext
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
        OnboardingScaffold(topSpacing: 180, header: { OnboardingHeader() }) {
            VStack(spacing: 0) {
                Spacer()

                // Main content in the middle of the container
                VStack(spacing: 20) {
                    if let bazi {
                        // Bazi pillars in center
                        let pillars: [Ganzhi] = [
                            bazi.yearGanzhi,
                            bazi.monthGanzhi,
                            bazi.dayGanzhi,
                            bazi.hourGanzhi
                        ]

                        HStack(spacing: 24) {
                            ForEach(0..<pillars.count, id: \.self) { index in
                                let pillar = pillars[index]
                                let stemIndex = index * 2
                                let branchIndex = index * 2 + 1
                                let isDayPillar = (index == 2)

                                VStack(spacing: 8) {
                                    Text(pillar.heavenlyStem)
                                        .font(AppFonts.title)
                                        .foregroundStyle(colorForHeavenlyStem(pillar.heavenlyStem))
                                        .scaleEffect(animatePillars ? (isDayPillar && isDayMasterHighlighted ? 1.08 : 1.0) : 0.9)
                                        .opacity(animatePillars ? 1 : 0.7)
                                        .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 2)
                                        .animation(characterAnimation(index: stemIndex), value: animatePillars)

                                    Text(pillar.earthlyBranch)
                                        .font(AppFonts.title)
                                        .foregroundStyle(colorForEarthlyBranch(pillar.earthlyBranch))
                                        .scaleEffect(animatePillars ? 1 : 0.9)
                                        .opacity(animatePillars ? 1 : 0.7)
                                        .shadow(color: Color.black.opacity(0.14), radius: 4, x: 0, y: 2)
                                        .animation(characterAnimation(index: branchIndex), value: animatePillars)
                                }
                            }
                        }
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
                        Text("你的八字日主是\(dayHeavenlyStem)，\n为你分配「\(partnerName)」作为你的伙伴，\n希望你们相处的愉快！")
                            .font(AppFonts.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppColors.textBlack)
                            .padding(.top, 8)
                    }
                }
                .onAppear {
                    // Trigger entrance animation for pillars
                    animatePillars = false
                    isDayMasterHighlighted = false
                    DispatchQueue.main.async {
                        animatePillars = true
                        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                            isDayMasterHighlighted.toggle()
                        }
                    }
                }

                Spacer()

                // Bottom CTA block, aligned with other onboarding screens
                VStack(spacing: 12) {
                    PrimaryButton(
                        action: onNext,
                        style: .init(variant: .filled, verticalPadding: 12)
                    ) {
                        Text("下一步")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }
}

#Preview {
    let state = OnboardingState()
    BaziAnalysisResultView(state: state)
}
