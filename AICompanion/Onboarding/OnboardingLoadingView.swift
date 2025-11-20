import SwiftUI
import Combine

public struct OnboardingLoadingView: View {
    @ObservedObject private var state: OnboardingState
    private let wheelNamespace: Namespace.ID?
    @State private var isSpinning = false
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

            VStack {
                Spacer()

                Group {
                    if let wheelNamespace {
                        Image("fortune_wheel_small")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160, height: 160)
                            .matchedGeometryEffect(id: "fortuneWheel", in: wheelNamespace)
                    } else {
                        Image("fortune_wheel_small")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160, height: 160)
                    }
                }
                .rotationEffect(Angle.degrees(isSpinning ? 360 : 0))
                .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: isSpinning)

                Spacer()
                HStack(spacing: 0) {
                    let characters = Array("为你计算生辰八字中")
                    ForEach(characters.indices, id: \.self) { index in
                        let char = String(characters[index])
                        Text(char)
                            .baselineOffset(sin(wavePhase + Double(index) * 0.6) * 4)
                    }
                }
                .font(AppFonts.small)
                .foregroundStyle(AppColors.neutralGray)
                .padding(.bottom, 40)
                .onReceive(Timer.publish(every: 0.06, on: .main, in: .common).autoconnect()) { _ in
                    wavePhase += 0.25
                }
            }
        }
        .onAppear {
            print("🔄 OnboardingLoadingView appeared")
            isSpinning = true
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
