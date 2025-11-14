import SwiftUI

public struct OnboardingNicknameView: View {
    @ObservedObject private var state: OnboardingState
    private let onContinue: () -> Void

    public init(state: OnboardingState, onContinue: @escaping () -> Void = {}) {
        self.state = state
        self.onContinue = onContinue
    }

    public var body: some View {
        OnboardingScaffold(header: header) {
            VStack(spacing: 24) {
                Text("👋让我们认识一下")
                    .font(AppFonts.subtitle)
                    .foregroundStyle(AppColors.textBlack)

                Text("我要如何称呼你呢？")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textBlack)

                AppTextField("昵称", text: Binding(
                    get: { state.nickname },
                    set: { newValue in
                        state.nickname = state.sanitizeNickname(newValue)
                    }
                ))

                PrimaryButton(action: { onContinue() }) {
                    Text("开始")
                }
                .disabled(!state.isNicknameValid)
                .opacity(state.isNicknameValid ? 1 : 0.6)

                Text("请接受用户隐私政策和使用协议")
                    .font(AppFonts.small)
                    .foregroundStyle(AppColors.neutralGray)
            }
        }
    }

    @ViewBuilder
    private func header() -> some View {
        Image("fortune_wheel_small")
            .resizable()
            .scaledToFit()
            .frame(width: 72, height: 72)
            .padding(.top, 24)
    }
}
