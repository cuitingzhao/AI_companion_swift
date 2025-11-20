import SwiftUI

public struct KYCIntroView: View {
    @ObservedObject private var state: OnboardingState
    private let onConfirm: () -> Void
    private let onSkip: () -> Void

    @State private var displayedText1: String = ""
    @State private var displayedText2: String = ""
    @State private var isTypingFirst: Bool = false
    @State private var isTypingSecond: Bool = false

    public init(
        state: OnboardingState,
        onConfirm: @escaping () -> Void = {},
        onSkip: @escaping () -> Void = {}
    ) {
        self.state = state
        self.onConfirm = onConfirm
        self.onSkip = onSkip
    }

    private var dayHeavenlyStem: String {
        state.lastSubmitResponse?.bazi?.dayGanzhi.heavenlyStem ?? ""
    }

    private var partnerName: String {
        guard let element = elementForStem(dayHeavenlyStem) else { return "伙伴" }
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

    private func startTyping() {
        guard !isTypingFirst && !isTypingSecond else { return }

        displayedText1 = ""
        displayedText2 = ""

        let fullText1 = "👋 你好呀，我是你的五行伙伴「\(partnerName)」"
        let fullText2 = "我刚刚根据你的八字推测了你的性格，可以请你确认一下吗？"

        isTypingFirst = true
        type(text: fullText1, intoFirst: true) {
            isTypingFirst = false
            isTypingSecond = true
            type(text: fullText2, intoFirst: false) {
                isTypingSecond = false
            }
        }
    }

    private func type(text: String, intoFirst: Bool, completion: @escaping () -> Void) {
        let characters = Array(text)

        func step(_ index: Int) {
            if index >= characters.count {
                completion()
                return
            }

            let char = characters[index]
            if intoFirst {
                displayedText1.append(char)
            } else {
                displayedText2.append(char)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                step(index + 1)
            }
        }

        step(0)
    }

    public var body: some View {
        OnboardingScaffold(topSpacing: 60, header: { EmptyView() }) {
            VStack(spacing: 24) {
                Spacer()

                VStack(alignment: .leading, spacing: 16) {
                    if !displayedText1.isEmpty || isTypingFirst {
                        HStack(alignment: .top) {
                            Text(displayedText1)
                                .font(AppFonts.body)
                                .foregroundStyle(AppColors.textBlack)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(18)
                                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                            Spacer()
                        }
                    }

                    if !displayedText2.isEmpty || isTypingSecond {
                        HStack(alignment: .top) {
                            Text(displayedText2)
                                .font(AppFonts.body)
                                .foregroundStyle(AppColors.textBlack)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(18)
                                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: 300, alignment: .leading)

                Spacer()

                VStack(spacing: 12) {
                    PrimaryButton(
                        action: {
                            // Call external handler if provided
                            onConfirm()
                            // Also ensure navigation advances into personality KYC step
                            state.currentPersonalityIndex = 0
                            state.currentStep = .kycPersonality
                        },
                        style: .init(variant: .filled, verticalPadding: 12)
                    ) {
                        Text("好的，开始吧")
                            .foregroundStyle(.white)
                    }

                    PrimaryButton(
                        action: onSkip,
                        style: .init(variant: .outlined, verticalPadding: 12)
                    ) {
                        Text("暂时跳过")
                            .foregroundStyle(AppColors.purple)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startTyping()
        }
    }
}

#Preview {
    KYCIntroView(state: OnboardingState())
}
