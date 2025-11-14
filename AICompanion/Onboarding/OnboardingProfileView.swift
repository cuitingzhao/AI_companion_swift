import SwiftUI

public struct OnboardingProfileView: View {
    @ObservedObject private var state: OnboardingState
    private let onFinish: () -> Void

    public init(state: OnboardingState, onFinish: @escaping () -> Void = {}) {
        self.state = state
        self.onFinish = onFinish
    }

    public var body: some View {
        OnboardingScaffold(header: header) {
            VStack(alignment: .leading, spacing: 20) {
                Text("你好呀！ \(state.nickname.isEmpty ? "" : state.nickname)")
                    .font(AppFonts.subtitle)
                    .foregroundStyle(AppColors.textBlack)

                Text("为了做一个合格的五行伙伴，我需要以下信息计算你的生辰八字")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textBlack)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 6)

                HStack(spacing: 12) {
                    GenderChip("女", isSelected: state.gender == .female) {
                        state.gender = .female
                    }
                    GenderChip("男", isSelected: state.gender == .male) {
                        state.gender = .male
                    }
                }

                VStack(spacing: 16) {
                    // Date + Time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("出生日期和时间（公历）")
                            .font(AppFonts.small)
                            .foregroundStyle(AppColors.neutralGray)
                        DatePicker("出生日期和时间（公历）", selection: $state.birthDate, in: state.earliestAllowedDate...state.latestAllowedDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .padding(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(AppColors.textBlack, lineWidth: 1)
                            )
                    }

                    // City search
                    CitySearchField(text: $state.cityQuery) { city in
                        state.selectedCity = city
                    }
                }

                PrimaryButton(action: { onFinish() }) {
                    Text("开始")
                }
                .disabled(!state.isProfileValid)
                .opacity(state.isProfileValid ? 1 : 0.6)
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
