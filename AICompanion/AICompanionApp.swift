//
//  AICompanionApp.swift
//  AICompanion
//
//  Created by TZ CUI on 13/11/25.
//

import SwiftUI

@main
struct AICompanionApp: App {
    @StateObject private var onboardingState = OnboardingState()
    @Namespace private var wheelNamespace
    var body: some Scene {
        WindowGroup {
            ZStack {
                switch onboardingState.currentStep {
                case .intro:
                    OnboardingIntroView(state: onboardingState) {
                        print("🟣 Navigating from intro to nickname")
                        onboardingState.currentStep = .nickname
                    }
                case .nickname:
                    OnboardingNicknameView(state: onboardingState) {
                        print("🟣 Navigating from nickname to profile")
                        onboardingState.currentStep = .profile
                    }
                case .profile:
                    OnboardingProfileView(state: onboardingState, wheelNamespace: wheelNamespace) {
                        print("🟣 Navigating from profile to loading")
                        onboardingState.currentStep = .loading
                    }
                case .loading:
                    OnboardingLoadingView(state: onboardingState, wheelNamespace: wheelNamespace)
                case .baziResult:
                    BaziAnalysisResultView(state: onboardingState) {
                        print("🟣 Navigating from baziResult to kycIntro")
                        onboardingState.currentStep = .kycIntro
                    }
                case .kycIntro:
                    KYCIntroView(state: onboardingState) {
                        print("🟣 Navigating from kycIntro to kycPersonality")
                        onboardingState.currentPersonalityIndex = 0
                        onboardingState.currentStep = .kycPersonality
                    }
                case .kycPersonality:
                    KYCPersonalityReviewView(state: onboardingState)
                case .kycChat:
                    KYCChatView(state: onboardingState)
                case .kycEnd:
                    KYCEndView(state: onboardingState)
                }
            }
            .animation(.spring(response: 0.7, dampingFraction: 0.85), value: onboardingState.currentStep)
        }
    }
}
