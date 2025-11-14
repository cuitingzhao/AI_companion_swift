import SwiftUI

public struct OnboardingIntroView: View {
    @ObservedObject private var state: OnboardingState
    private let onStart: () -> Void
    @State private var isShowingPrivacyPolicy = false
    @State private var isShowingUserAgreement = false

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

                Image("five_elements_together")
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

                HStack(spacing: 8) {
                    Button(action: { state.acceptedTerms.toggle() }) {
                        Image(systemName: state.acceptedTerms ? "checkmark.square.fill" : "square")
                            .foregroundColor(state.acceptedTerms ? AppColors.purple : AppColors.neutralGray)
                    }
                    .buttonStyle(.plain)

                    Text("请接受")
                        .font(AppFonts.small)
                        .foregroundStyle(AppColors.neutralGray)

                    Button(action: { isShowingPrivacyPolicy = true }) {
                        Text("用户隐私政策")
                            .font(AppFonts.small)
                            .underline()
                            .foregroundStyle(AppColors.purple)
                    }
                    .buttonStyle(.plain)

                    Text("和")
                        .font(AppFonts.small)
                        .foregroundStyle(AppColors.neutralGray)

                    Button(action: { isShowingUserAgreement = true }) {
                        Text("使用协议")
                            .font(AppFonts.small)
                            .underline()
                            .foregroundStyle(AppColors.purple)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .alert("用户隐私政策", isPresented: $isShowingPrivacyPolicy) {
            Button("关闭", role: .cancel) { }
        } message: {
            Text("这里展示用户隐私政策的详细内容。")
        }
        .alert("使用协议", isPresented: $isShowingUserAgreement) {
            Button("关闭", role: .cancel) { }
        } message: {
            Text("这里展示使用协议的详细内容。")
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
