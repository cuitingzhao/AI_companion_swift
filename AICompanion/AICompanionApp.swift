//
//  AICompanionApp.swift
//  AICompanion
//
//  Created by TZ CUI on 13/11/25.
//

import SwiftUI

@main
struct AICompanionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var onboardingState = OnboardingState()
    @Namespace private var wheelNamespace
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                switch onboardingState.currentStep {
                case .splash:
                    // Show splash screen while checking auth state
                    SplashView()
                        .task {
                            await onboardingState.initializeFromAuthState()
                        }
                case .intro:
                    OnboardingIntroView(
                        state: onboardingState,
                        showLoginOption: onboardingState.showLoginOption,
                        onStart: {
                            print("🟣 Navigating from intro to profile")
                            onboardingState.currentStep = .profile
                        },
                        onLogin: {
                            print("🟣 Navigating from intro to login")
                            onboardingState.currentStep = .login
                        }
                    )
                case .login:
                    // Login/Register page for guest users or users who want to login
                    LoginView(
                        state: onboardingState,
                        onLoginSuccess: { isNewUser in
                            if isNewUser {
                                // New user who logged in: needs to complete onboarding
                                print("🟣 New user logged in, checking onboarding status")
                                Task {
                                    await onboardingState.initializeFromAuthState()
                                }
                            } else {
                                // Existing user: go to home
                                print("🟣 Existing user logged in, going to home")
                                onboardingState.currentStep = .home
                            }
                        },
                        onSkip: AuthManager.shared.isGuest ? {
                            // Guest user skips login, go to home
                            print("🟣 Guest user skipped login, going to home")
                            onboardingState.currentStep = .home
                        } : nil,
                        onBack: onboardingState.showLoginOption ? {
                            // User came from intro, go back to intro
                            print("🟣 Going back from login to intro")
                            onboardingState.currentStep = .intro
                        } : nil
                    )
                case .nickname:
                    // Nickname is now consolidated into intro view, redirect to profile
                    OnboardingIntroView(
                        state: onboardingState,
                        showLoginOption: onboardingState.showLoginOption,
                        onStart: {
                            print("🟣 Navigating from intro to profile")
                            onboardingState.currentStep = .profile
                        },
                        onLogin: {
                            print("🟣 Navigating from intro to login")
                            onboardingState.currentStep = .login
                        }
                    )
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
