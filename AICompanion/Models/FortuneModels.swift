import Foundation

public struct DailyFortuneContext: Codable {
    public let solarDate: String
    public let lunarDate: String
    public let currentDecade: String?

    private enum CodingKeys: String, CodingKey {
        case solarDate = "solar_date"
        case lunarDate = "lunar_date"
        case currentDecade = "current_decade"
    }
}

public struct DailyFortuneResponse: Codable {
    public let context: DailyFortuneContext
    // Legacy fields (now optional as API may not return them)
    public let fortuneLevel: String?
    public let good: String?
    public let avoid: String?
    public let reason: String?
    // New fields for 提运指南
    public let color: String?       // 幸运颜色
    public let food: String?        // 幸运食材
    public let direction: String?   // 幸运方位

    private enum CodingKeys: String, CodingKey {
        case context
        case fortuneLevel = "fortune_level"
        case good
        case avoid
        case reason
        case color
        case food
        case direction
    }
}
