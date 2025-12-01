import SwiftUI

public struct KYCPersonalityReviewView: View {
    @ObservedObject private var state: OnboardingState
    @State private var isSkipDialogPresented: Bool = false
    @State private var traitComments: [Int: String] = [:]
    @State private var isSubmittingFeedback: Bool = false

    public init(state: OnboardingState) {
        self.state = state
    }

    private var traits: [PersonalityTrait] {
        state.personalityTraits
    }

    private var totalCount: Int {
        traits.count
    }

    private var currentIndex: Int {
        guard totalCount > 0 else { return 0 }
        return min(max(state.currentPersonalityIndex, 0), totalCount - 1)
    }

    private var currentTrait: PersonalityTrait? {
        guard currentIndex < traits.count else { return nil }
        return traits[currentIndex]
    }

    private var selectedRating: OnboardingState.PersonalityAccuracy? {
        guard let trait = currentTrait else { return nil }
        return state.personalityTraitRatings[trait.id]
    }

    private var progressText: String {
        guard totalCount > 0 else { return "0/0" }
        return "\(currentIndex + 1)/\(totalCount)"
    }

    private var isLastTrait: Bool {
        totalCount > 0 && currentIndex == totalCount - 1
    }

    private var primaryButtonTitle: String {
        isLastTrait ? "完成" : "继续"
    }

    private func commentBinding(for traitId: Int) -> Binding<String> {
        Binding(
            get: { traitComments[traitId] ?? "" },
            set: { traitComments[traitId] = $0 }
        )
    }

    private func setRating(_ rating: OnboardingState.PersonalityAccuracy) {
        guard let trait = currentTrait else { return }
        state.personalityTraitRatings[trait.id] = rating
    }

    private func handlePrimaryAction() {
        guard totalCount > 0 else { return }
        if !isLastTrait {
            state.currentPersonalityIndex += 1
        } else {
            // Submit feedback to backend
            submitFeedback()
        }
    }

    private func submitFeedback() {
        guard let userId = state.submitUserId else {
            print("❌ No user ID available")
            return
        }

        let traitFeedbacks = state.personalityTraitRatings.map { (traitId, accuracy) -> TraitFeedback in
            let feedbackFlag: String
            switch accuracy {
            case .notAccurate:
                feedbackFlag = "not_accurate"
            case .partiallyAccurate:
                feedbackFlag = "somewhat_accurate"
            case .veryAccurate:
                feedbackFlag = "accurate"
            }
            let rawComment = traitComments[traitId]?.trimmingCharacters(in: .whitespacesAndNewlines)
            let comment: String?
            if accuracy == .veryAccurate {
                comment = nil
            } else if let text = rawComment, !text.isEmpty {
                comment = text
            } else {
                comment = nil
            }
            return TraitFeedback(traitId: traitId, feedbackFlag: feedbackFlag, comment: comment)
        }

        let request = OnboardingFeedbackRequest(userId: userId, traitFeedbacks: traitFeedbacks)

        isSubmittingFeedback = true

        Task {
            do {
                print("🚀 Submitting feedback...")
                let response = try await OnboardingAPI.shared.submitFeedback(request)
                print("✅ Feedback submitted successfully:", response.message)
                state.personalityEndSource = .fromFeedback
                state.currentStep = .kycPersonalityEnd
            } catch {
                print("❌ Feedback submission error:", error)
            }
            isSubmittingFeedback = false
        }
    }

    private func handleSkip() {
        isSkipDialogPresented = true
    }

    private func confirmSkip() {
        state.personalityEndSource = .skip
        state.currentStep = .kycPersonalityEnd
    }

    private func progressBar(progress: Double) -> some View {
        let clamped = max(0, min(1, progress))

        return ZStack(alignment: .leading) {
            Capsule()
                .fill(AppColors.purple.opacity(0.15))

            Capsule()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            AppColors.purple.opacity(0.4),
                            AppColors.purple
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .scaleEffect(x: clamped, y: 1, anchor: .leading)
        }
        .frame(height: 6)
    }

    private func optionButton(title: String, value: OnboardingState.PersonalityAccuracy) -> some View {
        let isSelected = selectedRating == value
        let background = AppColors.purple.opacity(isSelected ? 0.8 : 0.2)

        return Button(action: {
            setRating(value)
        }) {
            Text(title)
                .font(AppFonts.body)
                .foregroundStyle(isSelected ? AppColors.white : AppColors.purple)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(background)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    public var body: some View {
        OnboardingScaffold(topSpacing: 60, containerColor: Color.white.opacity(0.6), header: { EmptyView() }) {
            VStack(spacing: 24) {
                // Progress and title
                VStack(alignment: .leading, spacing: 8) {
                    Text(progressText)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textBlack)

                    if totalCount > 0 {
                        progressBar(progress: Double(currentIndex + 1) / Double(totalCount))
                            .frame(maxWidth: .infinity)
                    }
                }

                Text("这些性格描述准确吗？")
                    .font(AppFonts.large)
                    .foregroundStyle(AppColors.textBlack)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Personality card
                if let trait = currentTrait {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(trait.trait)
                            .font(AppFonts.body)
                            .foregroundStyle(AppColors.textBlack)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                } else {
                    Text("暂时没有需要你确认的性格描述")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.neutralGray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Options
                HStack(spacing: 12) {
                    optionButton(title: "不准", value: .notAccurate)
                    optionButton(title: "部分准", value: .partiallyAccurate)
                    optionButton(title: "准确", value: .veryAccurate)
                }

                if let trait = currentTrait,
                   selectedRating == .notAccurate || selectedRating == .partiallyAccurate {
                    AppTextField(
                        "如果觉得不准，可以简单说说哪里不太对（可选）",
                        text: commentBinding(for: trait.id)
                    )
                }

                Spacer()

                // Primary CTA
                VStack(spacing: 12) {
                    SimpleButton(
                        primaryButtonTitle,
                        variant: .filled,
                        isEnabled: selectedRating != nil,
                        action: handlePrimaryAction
                    )

                    SimpleButton(
                        "跳过",
                        variant: .outlined,
                        action: handleSkip
                    )
                }
            }
        }
        .overlay(
            Group {
                if isSubmittingFeedback {
                    ZStack {
                        Color.black.opacity(0.25)
                            .ignoresSafeArea()

                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(AppColors.purple)

                            Text("正在提交，请稍候")
                                .font(AppFonts.body)
                                .foregroundStyle(AppColors.textBlack)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .background(Color.white)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 6)
                    }
                }
            }
        )
        .overlay(
            AppDialog(
                isPresented: $isSkipDialogPresented,
                message: "了解你的性格能让我给出更好的建议，确定要跳过这个环节吗？",
                primaryTitle: "确定",
                primaryAction: {
                    confirmSkip()
                },
                secondaryTitle: "取消",
                secondaryAction: {},
                title: "确认跳过？"
            )
        )
    }
}

#Preview {
    let state = OnboardingState()
    KYCPersonalityReviewView(state: state)
}
