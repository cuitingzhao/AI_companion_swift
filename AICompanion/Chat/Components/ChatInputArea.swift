import SwiftUI

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
                
                Button(action: onToggleInputMode) {
                    Image(systemName: inputMode == .text ? "mic.fill" : "keyboard")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.purple)
                }
            }
        }
        .disabled(isSending)
    }
}
