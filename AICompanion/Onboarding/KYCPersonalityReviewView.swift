import SwiftUI

public struct KYCPersonalityReviewView: View {
    @ObservedObject private var state: OnboardingState

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
            return TraitFeedback(traitId: traitId, feedbackFlag: feedbackFlag, comment: nil)
        }

        let request = OnboardingFeedbackRequest(userId: userId, traitFeedbacks: traitFeedbacks)

        Task {
            do {
                print("🚀 Submitting feedback...")
                let response = try await OnboardingAPI.shared.submitFeedback(request)
                print("✅ Feedback submitted successfully:", response.message)
                state.currentStep = .kycChat
            } catch {
                print("❌ Feedback submission error:", error)
            }
        }
    }

    private func handleSkip() {
        guard let userId = state.submitUserId else {
            print("❌ No user ID available")
            return
        }

        let request = OnboardingSkipRequest(userId: userId)

        Task {
            do {
                print("🚀 Skipping personality review...")
                let response = try await OnboardingAPI.shared.skip(request)
                print("✅ Skipped successfully:", response.message)
                // TODO: Navigate to next step
            } catch {
                print("❌ Skip error:", error)
            }
        }
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
        let background = AppColors.purple.opacity(isSelected ? 0.6 : 0.2)

        return Button(action: {
            setRating(value)
        }) {
            Text(title)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.purple)
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

                Text("以下推测准确吗？")
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
                    Text("暂时没有可确认的性格描述")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.neutralGray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Options
                HStack(spacing: 12) {
                    optionButton(title: "不准", value: .notAccurate)
                    optionButton(title: "部分准", value: .partiallyAccurate)
                    optionButton(title: "很准", value: .veryAccurate)
                }

                Spacer()

                // Primary CTA
                VStack(spacing: 12) {
                    PrimaryButton(
                        action: handlePrimaryAction,
                        style: .init(variant: .filled, verticalPadding: 12)
                    ) {
                        Text(primaryButtonTitle)
                            .foregroundStyle(.white)
                    }

                    PrimaryButton(
                        action: handleSkip,
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
    KYCPersonalityReviewView(state: state)
}
