import SwiftUI

struct ChatDateDivider: View {
    let date: Date?
    
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(AppColors.neutralGray.opacity(0.5))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
            
            Text(formatDividerDate(date))
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.neutralGray)
                .lineLimit(1)
                .fixedSize()
            
            Rectangle()
                .fill(AppColors.neutralGray.opacity(0.5))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
    
    private func formatDividerDate(_ date: Date?) -> String {
        guard let date = date else { return "上次对话" }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return "上次对话 · " + formatter.string(from: date)
    }
}
