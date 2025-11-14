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
    var body: some Scene {
        WindowGroup {
             OnboardingIntroView(state: onboardingState) 
        }
    }
}
