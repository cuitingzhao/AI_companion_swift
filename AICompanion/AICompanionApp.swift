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
                        onboardingState.currentStep = .nickname
                    }
                case .nickname:
                    OnboardingNicknameView(state: onboardingState) {
                        onboardingState.currentStep = .profile
                    }
                case .profile:
                    OnboardingProfileView(state: onboardingState, wheelNamespace: wheelNamespace) {
                        onboardingState.currentStep = .loading
                    }
                case .loading:
                    OnboardingLoadingView(state: onboardingState, wheelNamespace: wheelNamespace)
                }
            }
            .animation(.spring(response: 0.7, dampingFraction: 0.85), value: onboardingState.currentStep)
        }
    }
}
