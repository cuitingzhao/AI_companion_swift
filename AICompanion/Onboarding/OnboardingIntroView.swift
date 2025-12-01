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
    
    private var canProceed: Bool {
        state.isNicknameValid && state.acceptedTerms
    }

    public var body: some View {
        OnboardingScaffold(
            topSpacing: 80,
            containerColor: AppColors.accentYellow.opacity(0.8),
            isCentered: true,
            verticalPadding: 48,
            header: {
                VStack(spacing: 8) {
                    GIFImage(name: "winking")
                        .frame(width: 180, height: 100)
                    
                    Text("陪你完成小目标的伙伴")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textMedium)
                }
            }
        ) {
            VStack(alignment: .center, spacing: 40) {
                // Nickname input section
                VStack(spacing: 12) {
                    Text("👋 让我们认识一下？")
                        .font(AppFonts.subtitle)
                        .foregroundStyle(AppColors.textBlack)

                    Text("我要如何称呼你呢？")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textMedium)

                    AppTextField("昵称", text: Binding(
                        get: { state.nickname },
                        set: { newValue in
                            state.nickname = state.sanitizeNickname(newValue)
                        }
                    ), backgroundColor: .white)
                    .frame(maxWidth: 280)
                }

                // Button and T&C section
                VStack(spacing: 12) {
                    Button(action: { onStart() }) {
                        Text("开始")
                            .font(AppFonts.cuteButton)
                            .foregroundStyle(.white)
                            .frame(maxWidth: 280)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                                    .fill(canProceed ? AppColors.primary : AppColors.primary.opacity(0.4))
                            )
                            .shadow(color: AppColors.shadowColor, radius: 6, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canProceed)

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
