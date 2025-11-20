import Foundation

public struct CalendarShichenInfo: Codable {
    public let earthlyBranch: String
    public let label: String

    enum CodingKeys: String, CodingKey {
        case earthlyBranch = "earthly_branch"
        case label
    }
}

public struct CalendarNextJieqiInfo: Codable {
    public let name: String
    public let solarDatetime: String
    public let solarDate: String

    enum CodingKeys: String, CodingKey {
        case name
        case solarDatetime = "solar_datetime"
        case solarDate = "solar_date"
    }
}

public struct CalendarInfoResponse: Codable {
    public let now: String
    public let solarDate: String
    public let lunarDate: String
    public let lunarFull: String
    public let shichen: CalendarShichenInfo?
    public let currentJieqi: String?
    public let nextJieqi: CalendarNextJieqiInfo?

    enum CodingKeys: String, CodingKey {
        case now
        case solarDate = "solar_date"
        case lunarDate = "lunar_date"
        case lunarFull = "lunar_full"
        case shichen
        case currentJieqi = "current_jieqi"
        case nextJieqi = "next_jieqi"
    }
}
