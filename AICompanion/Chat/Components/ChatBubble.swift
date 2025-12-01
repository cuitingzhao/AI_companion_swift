import SwiftUI
import UIKit

// MARK: - Neobrutalism Chat Bubble
struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.sender == .ai {
                // AI avatar - load from bundle Resources
                if let imagePath = Bundle.main.path(forResource: "diandian", ofType: "png"),
                   let uiImage = UIImage(contentsOfFile: imagePath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                } else {
                    // Fallback circle if image not found
                    Circle()
                        .fill(AppColors.purple.opacity(0.3))
                        .frame(width: 36, height: 36)
                }
                
                bubbleView(text: message.text, isUser: false, images: nil, imageURLs: nil)
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubbleView(text: message.text, isUser: true, images: message.images, imageURLs: message.imageURLs)
            }
        }
    }
    
    @ViewBuilder
    private func bubbleView(text: String, isUser: Bool, images: [UIImage]?, imageURLs: [String]?) -> some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
            // Display single image if present (we only support 1 image per message)
            // Priority: UIImage (current session) > URL (from history)
            if let image = images?.first {
                // Current session image (UIImage)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: NeoBrutal.radiusMedium))
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
            } else if let urlString = imageURLs?.first, let url = URL(string: urlString) {
                // History image (from URL) - use CachedAsyncImage for better reliability
                CachedAsyncImage(url: url)
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: NeoBrutal.radiusMedium))
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
            
            // Display text if not empty
            if !text.isEmpty {
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
    }
}
