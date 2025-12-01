import SwiftUI
import Combine

public struct OnboardingLoadingView: View {
    @ObservedObject private var state: OnboardingState
    private let wheelNamespace: Namespace.ID?  // Kept for API compatibility
    @State private var hasSubmitted = false
    @State private var wavePhase: Double = 0

    public init(state: OnboardingState, wheelNamespace: Namespace.ID? = nil) {
        self.state = state
        self.wheelNamespace = wheelNamespace
    }

    public var body: some View {
        ZStack {
            AppColors.gradientBackground
                .ignoresSafeArea()

            Image("star_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.6)

            VStack(spacing: 16) {
                Spacer()

                GIFImage(name: "thinking")
                    .frame(width: 180, height: 180)

                HStack(spacing: 0) {
                    let characters = Array("努力工作中")
                    ForEach(characters.indices, id: \.self) { index in
                        let char = String(characters[index])
                        Text(char)
                            .baselineOffset(sin(wavePhase + Double(index) * 0.6) * 4)
                    }
                }
                .font(AppFonts.large)
                .foregroundStyle(AppColors.neutralGray)
                .onReceive(Timer.publish(every: 0.06, on: .main, in: .common).autoconnect()) { _ in
                    wavePhase += 0.25
                }

                Spacer()
            }
        }
        .onAppear {
            print("🔄 OnboardingLoadingView appeared")
            if !hasSubmitted {
                print("🔄 Starting submit task...")
                hasSubmitted = true
                Task {
                    print("🔄 Task started, calling submitOnboarding()")
                    await state.submitOnboarding()
                    print("🔄 submitOnboarding() returned")
                    if state.lastSubmitResponse != nil {
                        print("🔄 Got response, transitioning to baziResult")
                        state.currentStep = .baziResult
                    } else {
                        print("⚠️ No response received")
                    }
                }
            } else {
                print("🔄 Already submitted, skipping")
            }
        }
    }
}

#Preview {
    OnboardingLoadingView(state: OnboardingState())
}
