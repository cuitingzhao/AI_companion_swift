import Foundation
import SwiftUI
import Combine

public final class OnboardingState: ObservableObject {
    enum StorageKeys {
        static let userId = "onboarding.userId"
        static let nickname = "onboarding.nickname"
        static let completed = "onboarding.completed"
        static let step = "onboarding.step"
    }

    public enum Step: String {
        case splash          // Initial loading state while checking auth
        case intro           // Onboarding intro (with or without login option)
        case login           // Login/Register page for guest users
        case nickname
        case profile
        case loading
        case baziResult
        case kycIntro
        case kycPersonality
        case kycPersonalityEnd
        case kycChat
        case kycEnd
        case goalChat
        case goalPlan
        case subscription    // Paywall for expired trial/subscription
        case home
    }

    public enum Gender: String, CaseIterable, Codable {
        case female
        case male
    }

    // Whether to show login option in OnboardingIntroView
    // true = no token (new user), false = logged-in user who hasn't completed onboarding
    @Published public var showLoginOption: Bool = true
    
    @Published public var currentStep: Step = .splash {
        didSet {
            persistCurrentStep()
        }
    }

    // Page 1
    @Published public var acceptedTerms: Bool = false

    // Page 2
    @Published public var nickname: String = ""

    // Page 3
    @Published public var gender: Gender = .female
    @Published public var birthDate: Date
    @Published public var cityQuery: String = ""
    @Published public var selectedCity: City? = nil

    @Published public var submitUserId: Int?
    @Published public var lastSubmitResponse: OnboardingSubmitResponse?
    @Published public var isSubmittingOnboarding: Bool = false
    @Published public var submitError: String?

    // Goal onboarding
    @Published public var currentGoalId: Int?
    @Published public var goalPlan: GoalPlanResponse?

    // KYC personality
    @Published public var personalityTraits: [PersonalityTrait] = []
    @Published public var currentPersonalityIndex: Int = 0
    @Published public var personalityTraitRatings: [Int: PersonalityAccuracy] = [:]

    public let nicknameMaxLength: Int = 12

    public enum KYCEndMode {
        case defaultGoal
        case skippedIcebreaking
    }

    @Published public var kycEndMode: KYCEndMode = .defaultGoal

    public init() {
        // Default a reasonable past date
        var comps = DateComponents()
        comps.year = 1990; comps.month = 1; comps.day = 1; comps.hour = 0; comps.minute = 0
        self.birthDate = Calendar.current.date(from: comps) ?? Date(timeIntervalSince1970: 0)
        // Note: We no longer restore from UserDefaults here.
        // The app entry point (AICompanionApp) will check AuthManager and route accordingly.
    }
    
    /// Called by AICompanionApp after checking auth state
    /// Routes user to the appropriate step based on their authentication status
    @MainActor
    public func initializeFromAuthState() async {
        let authManager = AuthManager.shared
        
        // Check if we have a stored token
        guard authManager.hasStoredToken else {
            // No token: new user, show onboarding with login option
            print("🔵 OnboardingState: No token found, showing intro with login option")
            showLoginOption = true
            currentStep = .intro
            return
        }
        
        // We have a token, fetch user info to determine routing
        do {
            try await authManager.fetchCurrentUser()
            
            guard let user = authManager.currentUser else {
                // Failed to get user, clear tokens and start fresh
                print("🔵 OnboardingState: Failed to get user info, clearing tokens")
                authManager.clearTokens()
                showLoginOption = true
                currentStep = .intro
                return
            }
            
            // Route based on user state
            if user.isGuest {
                // Guest user: show login/register page
                print("🔵 OnboardingState: Guest user, showing login page")
                submitUserId = user.id
                nickname = user.nickname
                currentStep = .login
            } else if !user.hasCompletedOnboarding {
                // Logged-in user who hasn't completed onboarding
                print("🔵 OnboardingState: Logged-in user, incomplete onboarding")
                submitUserId = user.id
                nickname = user.nickname
                showLoginOption = false
                currentStep = .intro
            } else {
                // Formal user with completed onboarding: check subscription
                print("🔵 OnboardingState: Formal user, checking subscription")
                submitUserId = user.id
                nickname = user.nickname
                
                // Check subscription status
                await SubscriptionManager.shared.initialize()
                if SubscriptionManager.shared.hasAccess {
                    print("🔵 OnboardingState: Has subscription access, going to home")
                    currentStep = .home
                } else {
                    print("🔵 OnboardingState: No subscription access, showing paywall")
                    currentStep = .subscription
                }
            }
        } catch {
            // Token might be invalid, clear and start fresh
            print("🔵 OnboardingState: Auth check failed - \(error), clearing tokens")
            authManager.clearTokens()
            showLoginOption = true
            currentStep = .intro
        }
    }

    public enum PersonalityAccuracy: String, Codable {
        case notAccurate
        case partiallyAccurate
        case veryAccurate
    }

    public enum PersonalityEndSource {
        case fromFeedback
        case skip
    }

    @Published public var personalityEndSource: PersonalityEndSource = .fromFeedback

    public var latestAllowedDate: Date {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: Date())
        // Today not acceptable → latest allowed is yesterday end of day
        return cal.date(byAdding: .second, value: -1, to: startOfToday) ?? Date()
    }

    public var earliestAllowedDate: Date {
        var comps = DateComponents()
        comps.year = 1900; comps.month = 1; comps.day = 1
        return Calendar.current.date(from: comps) ?? Date(timeIntervalSince1970: 0)
    }

    @MainActor
    public func submitOnboarding() async {
        print("🔵 submitOnboarding() called")
        print("🔵 Selected city:", selectedCity?.name ?? "nil")
        print("🔵 Nickname:", nickname)
        print("🔵 Gender:", gender.rawValue)
        print("🔵 Birth date:", birthDate)
        
        guard let city = selectedCity else {
            print("❌ No city selected, aborting")
            return
        }

        print("🟢 Starting submission...")
        isSubmittingOnboarding = true
        submitError = nil

        do {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            let birthTime = formatter.string(from: birthDate)
            print("🟢 Formatted birth time:", birthTime)

            let request = OnboardingSubmitRequest(
                nickname: nickname,
                birthTime: birthTime,
                cityId: city.id,
                gender: gender.rawValue
            )
            print("🚀 Submitting onboarding request:", request)
            print("🚀 Request details - nickname:", request.nickname, "birthTime:", request.birthTime, "cityId:", request.cityId, "gender:", request.gender)
            
            let response = try await OnboardingAPI.shared.submit(request)
            print("✅ Response received:", response)
            print("✅ User ID:", response.userId)
            
            lastSubmitResponse = response
            submitUserId = response.userId

            // Save tokens from response (guest user now has authentication)
            if let accessToken = response.accessToken,
               let refreshToken = response.refreshToken,
               let expiresIn = response.expiresIn {
                await AuthManager.shared.saveTokens(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    expiresIn: expiresIn
                )
                print("✅ Tokens saved after onboarding submit")
            }

            persistOnboardingUser()

            // Initialize KYC personality data
            personalityTraits = response.personalityTraits ?? []
            currentPersonalityIndex = 0
            personalityTraitRatings = [:]
        } catch {
            print("❌ Submit error:", error)
            print("❌ Error details:", error.localizedDescription)
            submitError = error.localizedDescription
        }

        isSubmittingOnboarding = false
        print("🔵 submitOnboarding() completed")
    }

    private func persistOnboardingUser() {
        guard let userId = submitUserId else { return }
        let defaults = UserDefaults.standard
        defaults.set(userId, forKey: StorageKeys.userId)
        defaults.set(nickname, forKey: StorageKeys.nickname)
    }

    private func persistCurrentStep() {
        let defaults = UserDefaults.standard
        defaults.set(currentStep.rawValue, forKey: StorageKeys.step)
    }

    public var isNicknameValid: Bool {
        Self.isValidNickname(nickname, maxLength: nicknameMaxLength)
    }

    public static func isValidNickname(_ value: String, maxLength: Int) -> Bool {
        guard !value.isEmpty && value.count <= maxLength else { return false }
        // Chinese Han characters or English letters only
        // No spaces, digits, or symbols
        let pattern = "^[\\p{Han}A-Za-z]{1,\(maxLength)}$"
        return value.range(of: pattern, options: .regularExpression) != nil
    }

    public func sanitizeNickname(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        // Remove anything that is not Chinese Han or English letters
        let pattern = "[^\\p{Han}A-Za-z]"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: trimmed.utf16.count)
            let cleaned = regex.stringByReplacingMatches(in: trimmed, options: [], range: range, withTemplate: "")
            return String(cleaned.prefix(nicknameMaxLength))
        } else {
            return String(trimmed.prefix(nicknameMaxLength))
        }
    }

    public var isProfileValid: Bool {
        selectedCity != nil && birthDate < latestAllowedDate
    }
}
