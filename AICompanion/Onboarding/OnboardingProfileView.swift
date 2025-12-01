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

    private var canProceed: Bool {
        state.isProfileValid
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
                    
                    // Text("陪你完成小目标的伙伴")
                    //     .font(AppFonts.body)
                    //     .foregroundStyle(AppColors.textMedium)
                }
            }
        ) { 
            VStack(alignment: .center, spacing: 20) {                
                VStack(alignment: .leading, spacing: 16) {
                    Text("你好呀！ \(state.nickname.isEmpty ? "" : state.nickname)")
                        .font(AppFonts.subtitle)
                        .foregroundStyle(AppColors.textBlack)

                    Text("为了探索你的性格，我需要你的生辰八字作为依据，请提供以下信息。")
                        .font(AppFonts.small)
                        .foregroundStyle(AppColors.textBlack)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 6)
                }
                .frame(maxWidth: 280, alignment: .leading)

                // Gender selection
                HStack(spacing: 12) {
                    GenderChip("♀女", isSelected: state.gender == .female) {
                        state.gender = .female
                    }
                    GenderChip("♂男", isSelected: state.gender == .male) {
                        state.gender = .male
                    }
                }
                .frame(maxWidth: 280)

                // Date and city pickers
                VStack(alignment: .leading, spacing: 16) {
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
                            .background(Color.white)
                            .cornerRadius(CuteClean.radiusMedium)
                        }
                        .buttonStyle(.plain)
                    }

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
                            .background(Color.white)
                            .cornerRadius(CuteClean.radiusMedium)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: 280)

                // Continue button
                Button(action: { onFinish() }) {
                    Text("继续")
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
                HStack {
                    Spacer()
                    Text("输入出生地点")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textBlack)
                    Spacer()
                }
                .overlay(alignment: .trailing) {
                    Button(action: { isShowingCityPicker = false }) {
                        Text("取消")
                            .font(AppFonts.small)
                            .foregroundStyle(AppColors.primary)
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 24)

                CitySearchField(text: $state.cityQuery) { city in
                    state.selectedCity = city
                    isShowingCityPicker = false
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 0)
            }
            .presentationDetents([.large])
            .interactiveDismissDisabled(false)
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
