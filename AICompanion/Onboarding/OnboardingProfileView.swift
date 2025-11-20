import SwiftUI

public struct OnboardingProfileView: View {
    @ObservedObject private var state: OnboardingState
    private let wheelNamespace: Namespace.ID?
    private let onFinish: () -> Void
    @State private var isShowingBirthDatePicker = false
    @State private var isShowingCityPicker = false

    public init(state: OnboardingState, wheelNamespace: Namespace.ID? = nil, onFinish: @escaping () -> Void = {}) {
        self.state = state
        self.wheelNamespace = wheelNamespace
        self.onFinish = onFinish
    }

    public var body: some View {
        OnboardingScaffold(topSpacing: 180, header: {
            if let wheelNamespace {
                OnboardingHeader(matchedId: "fortuneWheel", namespace: wheelNamespace)
            } else {
                OnboardingHeader()
            }
        }) {
            VStack(spacing: 0) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("你好呀！ \(state.nickname.isEmpty ? "" : state.nickname)")
                        .font(AppFonts.subtitle)
                        .foregroundStyle(AppColors.textBlack)

                    Text("为了做一个合格的五行伙伴，我需要以下信息来计算你的生辰八字。")
                        .font(AppFonts.small)
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
                        VStack(alignment: .leading, spacing: 8) {
                            Text("出生日期和时间（公历）")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.neutralGray)

                            Button(action: { isShowingBirthDatePicker = true }) {
                                HStack {
                                    Text(formattedBirthDate)
                                        .font(AppFonts.small)
                                        .foregroundStyle(AppColors.textBlack)

                                    Spacer()

                                    Image(systemName: "chevron.down")
                                        .foregroundColor(AppColors.neutralGray)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(AppColors.textBlack, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        // City search
                        VStack(alignment: .leading, spacing: 8) {
                            Text("出生地点")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.neutralGray)
                            Button(action: { isShowingCityPicker = true }) {
                                HStack {
                                    let displayText: String = {
                                        if let selected = state.selectedCity {
                                            return selected.name
                                        } else if !state.cityQuery.isEmpty {
                                            return state.cityQuery
                                        } else {
                                            return "请选择出生地点"
                                        }
                                    }()

                                    Text(displayText)
                                        .font(AppFonts.small)
                                        .foregroundStyle(
                                            state.selectedCity == nil && state.cityQuery.isEmpty
                                            ? AppColors.neutralGray
                                            : AppColors.textBlack
                                        )

                                    Spacer()

                                    Image(systemName: "chevron.down")
                                        .foregroundColor(AppColors.neutralGray)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(AppColors.textBlack, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Spacer()

                VStack(spacing: 12) {
                    PrimaryButton(
                        action: { onFinish() },
                        style: .init(variant: .filled, verticalPadding: 12)
                    ) {
                        Text("开始")
                            .foregroundStyle(.white)
                    }
                    .disabled(!state.isProfileValid)
                    .opacity(state.isProfileValid ? 1 : 0.6)
                }
            }
        }
        .sheet(isPresented: $isShowingBirthDatePicker) {
            VStack(spacing: 24) {
                Text("请选择你的出生日期和时间")
                    .font(AppFonts.subtitle)
                    .foregroundStyle(AppColors.textBlack)
                    .padding(.top, 16)
                
                VStack(spacing: 16) {
                    Text("日期")
                        .font(AppFonts.small)
                        .foregroundStyle(AppColors.neutralGray)
                    DatePicker(
                        "",
                        selection: $state.birthDate,
                        in: state.earliestAllowedDate...state.latestAllowedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.wheel)
                    .environment(\.locale, Locale(identifier: "zh_CN"))
                    .environment(\.font, AppFonts.small)
                    .labelsHidden()
                    
                    Text("时间")
                        .font(AppFonts.small)
                        .foregroundStyle(AppColors.neutralGray)
                        .padding(.top, 8)
                    DatePicker(
                        "",
                        selection: $state.birthDate,
                        displayedComponents: [.hourAndMinute]
                    )
                    .datePickerStyle(.wheel)
                    .environment(\.locale, Locale(identifier: "zh_CN"))
                    .environment(\.font, AppFonts.small)
                    .labelsHidden()
                }

                PrimaryButton(
                    action: { isShowingBirthDatePicker = false },
                    style: .init(variant: .filled, verticalPadding: 12)
                ) {
                    Text("完成")
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .sheet(isPresented: $isShowingCityPicker) {
            VStack(spacing: 16) {
                Text("选择出生地点")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textBlack)
                    .padding(.top, 16)

                CitySearchField(text: $state.cityQuery) { city in
                    state.selectedCity = city
                    isShowingCityPicker = false
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 0)
            }
        }
    }

    private var formattedBirthDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: state.birthDate)
    }
}

#Preview {
    OnboardingProfileView(state: OnboardingState(), wheelNamespace: nil, onFinish: {})
}
