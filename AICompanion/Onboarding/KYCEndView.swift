import SwiftUI

public struct KYCEndView: View {
    @ObservedObject private var state: OnboardingState
    private let onConfirm: () -> Void
    private let onSkip: () -> Void

    @State private var displayedIntro: String = ""
    @State private var displayedGoal: String = ""
    @State private var displayedAsk: String = ""
    @State private var isTypingIntro: Bool = false
    @State private var isTypingGoal: Bool = false
    @State private var isTypingAsk: Bool = false

    public init(
        state: OnboardingState,
        onConfirm: @escaping () -> Void = {},
        onSkip: @escaping () -> Void = {}
    ) {
        self.state = state
        self.onConfirm = onConfirm
        self.onSkip = onSkip
    }

    private var nickname: String {
        state.nickname
    }

    private var introText: String {
        switch state.kycEndMode {
        case .defaultGoal:
            return "❤️感谢你的分享，\(nickname)！"
        case .skippedIcebreaking:
            return "没关系，让我们保留这份神秘感，在未来的冒险中慢慢相识吧！✨"
        }
    }

    private var goalText: String {
        "作为你的养成系伙伴👼，我想帮你实现一个又一个有关个人成长的小目标！无论是“克服拖延”，还是“换工作”，我都可以帮你把它们变成每天的小任务~ 不过，像“中彩票”这种天上掉馅饼的好事，我可就无能为力了！🤷‍♀️"
    }

    private var askText: String {
        "所以，你是否有什么小目标🎯想跟我分享呢？"
    }

    private func startTyping() {
        guard !isTypingIntro && !isTypingGoal && !isTypingAsk else { return }

        displayedIntro = ""
        displayedGoal = ""
        displayedAsk = ""

        let fullIntro = introText
        let fullGoal = goalText
        let fullAsk = askText

        isTypingIntro = true
        type(text: fullIntro, target: .intro) {
            self.isTypingIntro = false
            self.isTypingGoal = true
            self.type(text: fullGoal, target: .goal) {
                self.isTypingGoal = false
                self.isTypingAsk = true
                self.type(text: fullAsk, target: .ask) {
                    self.isTypingAsk = false
                }
            }
        }
    }

    private enum TypeTarget {
        case intro, goal, ask
    }

    private func type(text: String, target: TypeTarget, completion: @escaping () -> Void) {
        let characters = Array(text)

        func step(_ index: Int) {
            if index >= characters.count {
                completion()
                return
            }

            let char = characters[index]
            switch target {
            case .intro:
                displayedIntro.append(char)
            case .goal:
                displayedGoal.append(char)
            case .ask:
                displayedAsk.append(char)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                step(index + 1)
            }
        }

        step(0)
    }

    public var body: some View {
        OnboardingScaffold(topSpacing: 60, containerColor: .clear, 
        header: { 
            VStack(spacing: 8) {                  
                GIFImage(name: "winking")
                        .frame(width: 180, height: 100)}
        
        }) {
            VStack(spacing: 24) {
                Spacer()

                VStack(alignment: .leading, spacing: 16) {
                    if !displayedIntro.isEmpty || isTypingIntro {
                        HStack(alignment: .top) {
                            Text(displayedIntro)
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

                    if !displayedGoal.isEmpty || isTypingGoal {
                        HStack(alignment: .top) {
                            Text(displayedGoal)
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

                    if !displayedAsk.isEmpty || isTypingAsk {
                        HStack(alignment: .top) {
                            Text(displayedAsk)
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
                    SimpleButton("继续", variant: .filled, action: onConfirm)
                    SimpleButton("暂时跳过", variant: .outlined, action: onSkip)
                }
            }
        }
        .onAppear {
            startTyping()
        }
    }
}

#Preview {
    let state = OnboardingState()
    state.nickname = "测试用户"
    return KYCEndView(state: state)
}
