import SwiftUI

struct ChatHeader: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColors.textBlack)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("AI 伙伴")
                    .font(AppFonts.subtitle)
                    .foregroundStyle(AppColors.textBlack)
                
                Text("随时与我聊天")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.neutralGray)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}
