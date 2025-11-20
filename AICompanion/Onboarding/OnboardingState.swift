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
        case intro
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
        case taskForToday
        case home
    }

    public enum Gender: String, CaseIterable, Codable {
        case female
        case male
    }

    @Published public var currentStep: Step = .intro {
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
        restorePersistedOnboardingIfAvailable()
    }

    private func restorePersistedOnboardingIfAvailable() {
        let defaults = UserDefaults.standard
        let savedUserId = defaults.integer(forKey: StorageKeys.userId)
        guard savedUserId > 0 else { return }

        submitUserId = savedUserId

        if let savedNickname = defaults.string(forKey: StorageKeys.nickname), !savedNickname.isEmpty {
            nickname = savedNickname
        }

        // Prefer restoring the last explicit step if available
        if let savedStepRaw = defaults.string(forKey: StorageKeys.step),
           let savedStep = Step(rawValue: savedStepRaw) {
            currentStep = savedStep
        } else if defaults.bool(forKey: StorageKeys.completed) {
            // Backwards compatibility: older版本只存了 completed，
            // 对这类老数据，我们直接送用户回首页，而不是重新进入目标引导。
            currentStep = .home
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
