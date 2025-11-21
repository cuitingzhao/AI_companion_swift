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
    public let fortuneLevel: String
    public let good: String
    public let avoid: String
    public let reason: String?

    private enum CodingKeys: String, CodingKey {
        case context
        case fortuneLevel = "fortune_level"
        case good
        case avoid
        case reason
    }
}
