import SwiftUI

// MARK: - Cute Clean Voice Input Button
public struct VoiceInputButton: View {
    public enum Style {
        case icon
        case longPress
    }

    @Binding private var text: String
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var isPressingLongPress: Bool = false
    private let style: Style
    private let onComplete: ((String) -> Void)?

    public init(text: Binding<String>, style: Style = .icon, onComplete: ((String) -> Void)? = nil) {
        self._text = text
        self.style = style
        self.onComplete = onComplete
    }

    public var body: some View {
        Group {
            switch style {
            case .icon:
                Button(action: toggleRecording) {
                    Image(systemName: speechRecognizer.isRecording ? "waveform.circle.fill" : "mic.fill")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(speechRecognizer.isRecording ? AppColors.cuteCoral : AppColors.cutePink)
                }
            case .longPress:
                longPressButton
            }
        }
        .onAppear {
            speechRecognizer.requestAuthorization()
        }
        .onChange(of: speechRecognizer.transcript) { _, newValue in
            guard !newValue.isEmpty else { return }
            text = newValue
        }
        .alert("语音输入不可用", isPresented: Binding(
            get: { speechRecognizer.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    speechRecognizer.errorMessage = nil
                }
            }
        )) {
            Button("好的", role: .cancel) {
                speechRecognizer.errorMessage = nil
            }
        } message: {
            if let message = speechRecognizer.errorMessage {
                Text(message)
            }
        }
    }

    private var longPressButton: some View {
        let isActive = isPressingLongPress || speechRecognizer.isRecording
        
        return Text(speechRecognizer.isRecording ? "松开 结束" : "按住 说话")
            .font(AppFonts.cuteButton)
            .foregroundStyle(isActive ? .white : AppColors.textDark)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(isActive ? AppColors.cuteCoral : AppColors.cutePeach)
            .cornerRadius(CuteClean.radiusMedium)
            .shadow(
                color: isActive ? AppColors.cuteCoral.opacity(0.3) : AppColors.shadowColor,
                radius: isActive ? 4 : 8,
                x: 0,
                y: isActive ? 2 : 4
            )
            .scaleEffect(isActive ? 0.97 : 1.0)
            .onLongPressGesture(minimumDuration: 0.01, maximumDistance: 50, pressing: { isPressing in
                withAnimation(.easeOut(duration: CuteClean.animationQuick)) {
                    isPressingLongPress = isPressing
                }
                if isPressing {
                    startRecordingIfNeeded()
                } else {
                    stopAndComplete()
                }
            }, perform: {})
    }

    private func startRecordingIfNeeded() {
        if !speechRecognizer.isRecording {
            text = ""
            speechRecognizer.startRecording()
        }
    }

    private func stopAndComplete() {
        guard speechRecognizer.isRecording else { return }
        speechRecognizer.stopRecording()
        // Give the recognizer a short moment to deliver the final
        // transcription result before we read from the bound text.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                onComplete?(trimmed)
            }
        }
    }

    private func toggleRecording() {
        if speechRecognizer.isRecording {
            speechRecognizer.stopRecording()
        } else {
            text = ""
            speechRecognizer.startRecording()
        }
    }
}
