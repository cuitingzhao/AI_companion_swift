import SwiftUI

public struct OnboardingIntroView: View {
    @ObservedObject private var state: OnboardingState
    private let onStart: () -> Void

    public init(state: OnboardingState, onStart: @escaping () -> Void = {}) {
        self.state = state
        self.onStart = onStart
    }

    public var body: some View {
        OnboardingScaffold(header: header) {
            VStack(spacing: 20) {
                Text("你的五行伙伴")
                    .font(AppFonts.subtitle)
                    .foregroundStyle(AppColors.textBlack)

                Image("five_elements_together", bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 360)

                Text("不只是陪伴\n还要帮你成为更好的自己")
                    .multilineTextAlignment(.center)
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.neutralGray)
                    .padding(.top, 6)

                PrimaryButton(action: { onStart() }) {
                    Text("开始")
                }
                .disabled(!state.acceptedTerms)
                .opacity(state.acceptedTerms ? 1 : 0.6)
                .padding(.top, 12)

                Toggle(isOn: $state.acceptedTerms) {
                    Text("请接受用户隐私政策和使用协议")
                        .font(AppFonts.small)
                        .foregroundStyle(AppColors.neutralGray)
                }
                .toggleStyle(.switch)
                .tint(AppColors.purple)
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
