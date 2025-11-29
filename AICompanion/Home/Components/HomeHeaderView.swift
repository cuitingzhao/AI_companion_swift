import SwiftUI

// MARK: - Home Header View

/// Header view for the daily tasks tab showing greeting, date, and fortune guide
struct HomeHeaderView: View {
    let calendarInfo: CalendarInfoResponse?
    let dailyFortune: DailyFortuneResponse?
    let yesterdaySummaryMessage: String?
    let isFortuneLoading: Bool
    let onLoadFortune: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Greeting title
            Text("\(timeBasedGreeting)，\(userNickname)")
                .font(AppFonts.large)
                .foregroundStyle(AppColors.textBlack)
            
            // Yesterday's task summary
            if let summaryMessage = yesterdaySummaryMessage {
                Text(summaryMessage)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textMedium)
            }
            
            // Date subtitle
            if let info = calendarInfo {
                Text("\(formattedSolarDate(info.solarDate))｜农历\(info.lunarDate)")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textMedium)
            }
            
            // Fortune guide container
            fortuneGuideContainer
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
    }
    
    // MARK: - Fortune Guide Container
    
    private var fortuneGuideContainer: some View {
        VStack(spacing: 12) {
            if let fortune = dailyFortune, fortune.color != nil || fortune.food != nil || fortune.direction != nil {
                // Show fortune data
                HStack(alignment: .top, spacing: 16) {
                    if let color = fortune.color {
                        fortuneInfoItem(icon: "paintpalette.fill", label: "幸运颜色", value: color)
                    }
                    if let food = fortune.food {
                        fortuneInfoItem(icon: "leaf.fill", label: "幸运食材", value: food)
                    }
                    if let direction = fortune.direction {
                        fortuneInfoItem(icon: "location.north.fill", label: "幸运方位", value: direction)
                    }
                }
            } else {
                // Show button to fetch fortune
                Button(action: onLoadFortune) {
                    HStack(spacing: 8) {
                        if isFortuneLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(AppColors.primary)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .medium))
                        }
                        Text("点击获取今日提运指南")
                            .font(AppFonts.cuteButton)
                    }
                    .foregroundStyle(AppColors.primary)
                }
                .buttonStyle(.plain)
                .disabled(isFortuneLoading)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(AppColors.cardWhite)
        .cornerRadius(CuteClean.radiusMedium)
        .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Fortune Info Item
    
    private func fortuneInfoItem(icon: String, label: String, value: String) -> some View {
        // Split by both English comma and Chinese comma into separate lines
        let values = value
            .replacingOccurrences(of: "，", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        return VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.primary)
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textLight)
            VStack(spacing: 2) {
                ForEach(values, id: \.self) { item in
                    Text(item)
                        .font(AppFonts.small)
                        .foregroundStyle(AppColors.textBlack)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helpers
    
    /// Time-based greeting
    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "早上好"
        case 12..<14:
            return "中午好"
        case 14..<18:
            return "下午好"
        default:
            return "晚上好"
        }
    }
    
    /// Get nickname from UserDefaults
    private var userNickname: String {
        UserDefaults.standard.string(forKey: "onboarding.nickname") ?? ""
    }
    
    /// Format solar date to Chinese format
    private func formattedSolarDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let output = DateFormatter()
        output.locale = Locale(identifier: "zh_CN")
        output.dateFormat = "yyyy年M月d日"
        return output.string(from: date)
    }
}
