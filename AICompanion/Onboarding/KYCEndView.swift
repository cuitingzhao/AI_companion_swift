import SwiftUI

public struct KYCEndView: View {
    @ObservedObject private var state: OnboardingState
    private let onConfirm: () -> Void
    private let onSkip: () -> Void

    @State private var displayedIntro: String = ""
    @State private var displayedGoal: String = ""
    @State private var isTypingIntro: Bool = false
    @State private var isTypingGoal: Bool = false

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
            return "\(nickname)，我已经对你有了初步的了解。"
        case .skippedIcebreaking:
            return "哎呀，你跳过了破冰环节，那就让我们之后慢慢地相互了解吧。"
        }
    }

    private var goalText: String {
        "有什么近期或者长期的个人成长目标吗？我会根据你的目标制定日常生活中的小任务，帮你实现这些目标。比如“克服拖延”，“换工作”，“减肥”等等。但是类似“中彩票”之类和个人成长无关的目标，我也没办法帮忙哦🤷‍♀️"
    }

    private func startTyping() {
        guard !isTypingIntro && !isTypingGoal else { return }

        displayedIntro = ""
        displayedGoal = ""

        let fullIntro = introText
        let fullGoal = goalText

        isTypingIntro = true
        type(text: fullIntro, intoIntro: true) {
            isTypingIntro = false
            isTypingGoal = true
            type(text: fullGoal, intoIntro: false) {
                isTypingGoal = false
            }
        }
    }

    private func type(text: String, intoIntro: Bool, completion: @escaping () -> Void) {
        let characters = Array(text)

        func step(_ index: Int) {
            if index >= characters.count {
                completion()
                return
            }

            let char = characters[index]
            if intoIntro {
                displayedIntro.append(char)
            } else {
                displayedGoal.append(char)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                step(index + 1)
            }
        }

        step(0)
    }

    public var body: some View {
        OnboardingScaffold(topSpacing: 60, containerColor: .clear, header: { EmptyView() }) {
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
                }
                .frame(maxWidth: 300, alignment: .leading)

                Spacer()

                VStack(spacing: 12) {
                    PrimaryButton(
                        action: onConfirm,
                        style: .init(variant: .filled, verticalPadding: 12)
                    ) {
                        Text("继续")
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
