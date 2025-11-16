import SwiftUI

public struct KYCEndView: View {
    @ObservedObject private var state: OnboardingState
    private let onConfirm: () -> Void
    private let onSkip: () -> Void

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

    private var messageText: String {
        "\(nickname)，我已经对你有了初步的了解。请告诉我，你有什么近期或者长期的目标吗？我会根据你的目标，制定日常生活中的小任务，帮你实现目标。比如“克服拖延”，“找一份 AI 相关的工作”，“在职场更有竞争力”等等。如果目标不够实际，比如“中彩票”， 我会拒绝的哦。"
    }

    public var body: some View {
        OnboardingScaffold(topSpacing: 60, header: { EmptyView() }) {
            VStack(spacing: 24) {
                Spacer()

                VStack(alignment: .leading, spacing: 16) {
                    Text(messageText)
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textBlack)
                        .multilineTextAlignment(.leading)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)

                Spacer()

                VStack(spacing: 12) {
                    PrimaryButton(
                        action: onConfirm,
                        style: .init(variant: .filled, verticalPadding: 12)
                    ) {
                        Text("确认")
                            .foregroundStyle(.white)
                    }

                    PrimaryButton(
                        action: onSkip,
                        style: .init(variant: .outlined, verticalPadding: 12)
                    ) {
                        Text("跳过")
                            .foregroundStyle(AppColors.purple)
                    }
                }
            }
        }
    }
}

#Preview {
    let state = OnboardingState()
    state.nickname = "测试用户"
    return KYCEndView(state: state)
}
