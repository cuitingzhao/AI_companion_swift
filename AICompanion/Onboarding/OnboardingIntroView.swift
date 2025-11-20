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
        OnboardingScaffold(topSpacing: 180, header: { OnboardingHeader() }) {
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 16) {
                    Text("你的五行伙伴")
                        .font(AppFonts.large)
                        .foregroundStyle(AppColors.textBlack)

                    Image("five_elements_together")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 280)

                    Text("不止是陪伴，\n也想帮你成为更好的自己")
                        .multilineTextAlignment(.center)
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.neutralGray)
                        .padding(.top, 4)
                }
                
                Spacer()

                VStack(spacing: 12) {
                    PrimaryButton(
                        action: { onStart() },
                        style: .init(variant: .filled, verticalPadding: 12)
                    ) {
                        Text("开始")
                            .foregroundStyle(.white)
                    }
                    .disabled(!state.acceptedTerms)
                    .opacity(state.acceptedTerms ? 1 : 0.6)

                    HStack(spacing: 8) {
                        Button(action: { state.acceptedTerms.toggle() }) {
                            Image(systemName: state.acceptedTerms ? "checkmark.square.fill" : "square")
                                .foregroundColor(state.acceptedTerms ? AppColors.purple : AppColors.neutralGray)
                        }
                        .buttonStyle(.plain)

                        Text("请先阅读并同意")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.neutralGray)

                        Button(action: { isShowingPrivacyPolicy = true }) {
                            Text("用户隐私政策")
                                .font(AppFonts.caption)
                                .underline()
                                .foregroundStyle(AppColors.purple)
                        }
                        .buttonStyle(.plain)

                        Text("和")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.neutralGray)

                        Button(action: { isShowingUserAgreement = true }) {
                            Text("使用协议")
                                .font(AppFonts.caption)
                                .underline()
                                .foregroundStyle(AppColors.purple)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
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

}

#Preview {
    OnboardingIntroView(state: OnboardingState(), onStart: {})
}
