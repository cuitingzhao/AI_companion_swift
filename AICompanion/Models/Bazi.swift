import Foundation

public struct Ganzhi: Codable, Equatable {
    public let heavenlyStem: String
    public let earthlyBranch: String
    public let hiddenStems: [String]

    public init(heavenlyStem: String, earthlyBranch: String, hiddenStems: [String] = []) {
        self.heavenlyStem = heavenlyStem
        self.earthlyBranch = earthlyBranch
        self.hiddenStems = hiddenStems
    }

    private enum CodingKeys: String, CodingKey {
        case heavenlyStem = "heavenly_stem"
        case earthlyBranch = "earthly_branch"
        case hiddenStems = "hidden_stems"
    }
}

public struct BaziData: Codable, Equatable {
    public let yearGanzhi: Ganzhi
    public let monthGanzhi: Ganzhi
    public let dayGanzhi: Ganzhi
    public let hourGanzhi: Ganzhi

    public init(yearGanzhi: Ganzhi, monthGanzhi: Ganzhi, dayGanzhi: Ganzhi, hourGanzhi: Ganzhi) {
        self.yearGanzhi = yearGanzhi
        self.monthGanzhi = monthGanzhi
        self.dayGanzhi = dayGanzhi
        self.hourGanzhi = hourGanzhi
    }

    private enum CodingKeys: String, CodingKey {
        case yearGanzhi = "year_ganzhi"
        case monthGanzhi = "month_ganzhi"
        case dayGanzhi = "day_ganzhi"
        case hourGanzhi = "hour_ganzhi"
    }
}

public struct BaziAnalysisResult: Codable, Equatable {
    public let bodyStrength: String
    public let usefulGods: [String]
    public let favorableGods: [String]
    public let unfavorableGods: [String]
    public let chartText: String?

    public init(
        bodyStrength: String,
        usefulGods: [String],
        favorableGods: [String],
        unfavorableGods: [String],
        chartText: String? = nil
    ) {
        self.bodyStrength = bodyStrength
        self.usefulGods = usefulGods
        self.favorableGods = favorableGods
        self.unfavorableGods = unfavorableGods
        self.chartText = chartText
    }

    private enum CodingKeys: String, CodingKey {
        case bodyStrength = "body_strength"
        case usefulGods = "useful_gods"
        case favorableGods = "favorable_gods"
        case unfavorableGods = "unfavorable_gods"
        case chartText = "chart_text"
    }
}
