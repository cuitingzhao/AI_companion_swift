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
                        print("🟣 Navigating from intro to profile")
                        onboardingState.currentStep = .profile
                    }
                case .nickname:
                    // Nickname is now consolidated into intro view, redirect to profile
                    OnboardingIntroView(state: onboardingState) {
                        print("🟣 Navigating from intro to profile")
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
                    BaziAnalysisResultView(
                        state: onboardingState,
                        onStart: {
                            print("🟣 Navigating from baziResult to kycPersonality")
                            onboardingState.currentPersonalityIndex = 0
                            onboardingState.currentStep = .kycPersonality
                        },
                        onSkip: {
                            print("🟣 Skipping KYC, navigating to goalChat")
                            UserDefaults.standard.set(true, forKey: OnboardingState.StorageKeys.completed)
                            onboardingState.currentStep = .goalChat
                        }
                    )
                case .kycIntro:
                    // KYCIntroView is now consolidated into BaziAnalysisResultView, redirect to kycPersonality
                    KYCPersonalityReviewView(state: onboardingState)
                case .kycPersonality:
                    KYCPersonalityReviewView(state: onboardingState)
                case .kycPersonalityEnd:
                    PersonalityReviewEndView(state: onboardingState)
                case .kycChat:
                    KYCChatView(state: onboardingState)
                case .kycEnd:
                    KYCEndView(
                        state: onboardingState,
                        onConfirm: {
                            print("🟣 Navigating from kycEnd to goalChat")
                            UserDefaults.standard.set(true, forKey: OnboardingState.StorageKeys.completed)
                            onboardingState.currentStep = .goalChat
                        }
                    )
                case .goalChat:
                    GoalOnboardingChatView(state: onboardingState)
                case .goalPlan:
                    GoalPlanView(state: onboardingState)
                case .home:
                    HomeDailyTasksView(
                        userId: onboardingState.submitUserId
                    )
                }
            }
            .animation(.spring(response: 0.7, dampingFraction: 0.85), value: onboardingState.currentStep)
        }
    }
}
