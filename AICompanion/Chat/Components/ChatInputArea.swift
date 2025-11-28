import SwiftUI

// MARK: - Cute Clean Chat Input Area
struct ChatInputArea: View {
    @Binding var draftMessage: String
    @Binding var inputMode: ChatViewInputMode
    let isSending: Bool
    let onSend: () -> Void
    let onVoiceComplete: (String) -> Void
    let onToggleInputMode: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                if inputMode == .text {
                    AppTextField(
                        "请输入内容",
                        text: $draftMessage,
                        submitLabel: SubmitLabel.send,
                        onSubmit: {
                            onSend()
                        }
                    )
                } else {
                    VoiceInputButton(
                        text: $draftMessage,
                        style: .longPress,
                        onComplete: { text in
                            onVoiceComplete(text)
                        }
                    )
                }
                
                // Cute Clean: Circular toggle button with soft colors
                Button(action: onToggleInputMode) {
                    Image(systemName: inputMode == .text ? "mic.fill" : "keyboard.fill")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(inputMode == .text ? AppColors.cuteCoral : AppColors.neoPurple)
                        .frame(width: 44, height: 44)
                        .background(inputMode == .text ? AppColors.cutePeach : AppColors.bgMintLight)
                        .clipShape(Circle())
                        .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
                }
            }
        }
        .disabled(isSending)
        .opacity(isSending ? 0.6 : 1)
    }
}
