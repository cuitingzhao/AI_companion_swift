import Foundation
import SwiftUI
import Combine

public final class OnboardingState: ObservableObject {
    public enum Gender: String, CaseIterable, Codable {
        case female
        case male
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

    public let nicknameMaxLength: Int = 12

    public init() {
        // Default a reasonable past date
        var comps = DateComponents()
        comps.year = 1990; comps.month = 1; comps.day = 1; comps.hour = 0; comps.minute = 0
        self.birthDate = Calendar.current.date(from: comps) ?? Date(timeIntervalSince1970: 0)
    }

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
