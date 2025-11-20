import SwiftUI

public struct PersonalityReviewEndView: View {
    @ObservedObject private var state: OnboardingState
    @State private var displayedText1: String = ""
    @State private var displayedText2: String = ""
    @State private var isTypingFirst: Bool = false
    @State private var isTypingSecond: Bool = false
    @State private var isShowingSkipDialog: Bool = false

    public init(state: OnboardingState) {
        self.state = state
    }

    private func startTyping() {
        guard !isTypingFirst && !isTypingSecond else { return }

        displayedText1 = ""
        displayedText2 = ""

        let fullText1: String
        switch state.personalityEndSource {
        case .fromFeedback:
            fullText1 = "不错哦，我现在已经大致对你的性格有了一个了解。"
        case .skip:
            fullText1 = "好的，那就让我在聊天中慢慢了解你的性格"
        }
        let fullText2 = "除了陪伴，我的另一个使命是帮你完成一个又一个小目标，成为你想成为的自己。所以我想了解一下你的基本状况，你同意吗？"

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
        OnboardingScaffold(topSpacing: 60, containerColor: .clear, header: { EmptyView() }) {
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
                            state.currentStep = .kycChat
                        },
                        style: .init(variant: .filled, verticalPadding: 12)
                    ) {
                        Text("继续")
                            .foregroundStyle(.white)
                    }

                    PrimaryButton(
                        action: { isShowingSkipDialog = true },
                        style: .init(variant: .outlined, verticalPadding: 12)
                    ) {
                        Text("跳过")
                            .foregroundStyle(AppColors.purple)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startTyping()
        }
        .overlay(
            AppDialog(
                isPresented: $isShowingSkipDialog,
                message: "对你基本情况的了解有助于我提供更恰当的建议，确定要跳过这个环节吗？",
                primaryTitle: "确认",
                primaryAction: {
                    state.kycEndMode = .skippedIcebreaking
                    state.currentStep = .kycEnd
                },
                secondaryTitle: "取消",
                secondaryAction: {},
                title: "确认跳过？"
            )
        )
    }
}

#Preview {
    PersonalityReviewEndView(state: OnboardingState())
}
