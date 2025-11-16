import Foundation
import AVFoundation
import Speech
import Combine

public final class SpeechRecognizer: NSObject, ObservableObject {
    @Published public private(set) var isRecording: Bool = false
    @Published public private(set) var transcript: String = ""
    @Published public private(set) var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published public var errorMessage: String?

    private let speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    public override init() {
        // Prefer Chinese locale, fall back to current locale if needed
        if let zhRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN")) {
            self.speechRecognizer = zhRecognizer
        } else {
            self.speechRecognizer = SFSpeechRecognizer()
        }
        super.init()
    }

    public func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                if status != .authorized {
                    self?.errorMessage = "语音识别权限未开启，请在系统设置中允许麦克风和听写权限。"
                }
            }
        }

        #if os(iOS)
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            if !granted {
                DispatchQueue.main.async {
                    self?.errorMessage = "麦克风权限未开启，请在系统设置中允许麦克风权限。"
                }
            }
        }
        #endif
    }

    public func startRecording() {
        guard !isRecording else { return }

        guard authorizationStatus == .authorized || authorizationStatus == .notDetermined else {
            errorMessage = "当前没有语音识别权限。"
            return
        }

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "语音识别服务暂不可用，请稍后再试。"
            return
        }

        recognitionTask?.cancel()
        recognitionTask = nil

        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "无法启动音频会话：\(error.localizedDescription)"
            return
        }
        #endif

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else {
            errorMessage = "无法创建语音识别请求。"
            return
        }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            errorMessage = "无法启动音频引擎：\(error.localizedDescription)"
            recognitionRequest.endAudio()
            return
        }

        DispatchQueue.main.async {
            self.transcript = ""
            self.errorMessage = nil
            self.isRecording = true
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }

            if let result = result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.transcript = text
                }
            }

            if let error = error {
                // Recognition errors (including normal cancellation) are noisy and
                // often not actionable for the user. Log them but don't surface
                // as user-facing alerts to avoid repeated "语音输入不可用" popups
                // when the user finishes a recording.
                print("Speech recognition error: \(error.localizedDescription)")
                self.stopRecordingInternal()
                return
            }

            if result?.isFinal == true {
                self.stopRecordingInternal()
            }
        }
    }

    public func stopRecording() {
        stopRecordingInternal()
    }

    private func stopRecordingInternal() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask = nil
        recognitionRequest = nil

        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
}
