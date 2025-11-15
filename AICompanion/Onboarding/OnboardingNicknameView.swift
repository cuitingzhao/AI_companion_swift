import SwiftUI

public struct OnboardingNicknameView: View {
    @ObservedObject private var state: OnboardingState
    private let onContinue: () -> Void

    public init(state: OnboardingState, onContinue: @escaping () -> Void = {}) {
        self.state = state
        self.onContinue = onContinue
    }

    public var body: some View {
        OnboardingScaffold(topSpacing: 180, header: { OnboardingHeader() }) {
            VStack(spacing: 0) {
                Spacer()
                
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
                }
                
                Spacer()

                VStack(spacing: 12) {
                    PrimaryButton(
                        action: { onContinue() },
                        style: .init(variant: .filled, verticalPadding: 12)
                    ) {
                        Text("开始")
                            .foregroundStyle(.white)
                    }
                    .disabled(!state.isNicknameValid)
                    .opacity(state.isNicknameValid ? 1 : 0.6)
                    
                }
            }
        }
    }

}

#Preview {
    OnboardingNicknameView(state: OnboardingState(), onContinue: {})
}
