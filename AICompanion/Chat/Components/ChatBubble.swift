import SwiftUI

// MARK: - Neobrutalism Chat Bubble
struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.sender == .ai {
                bubbleView(text: message.text, isUser: false)
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubbleView(text: message.text, isUser: true)
            }
        }
    }
    
    private func bubbleView(text: String, isUser: Bool) -> some View {
        Text(text)
            .font(AppFonts.body)
            .foregroundStyle(isUser ? .white : AppColors.neoBlack)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isUser ? AppColors.neoPurple : .white)
            .cornerRadius(NeoBrutal.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: NeoBrutal.radiusMedium)
                    .stroke(AppColors.neoBlack, lineWidth: NeoBrutal.borderThin)
            )
            .shadow(
                color: AppColors.shadowColor,
                radius: 0,
                x: isUser ? -3 : 3,
                y: 3
            )
    }
}
