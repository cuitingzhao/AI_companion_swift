import SwiftUI

public struct OnboardingLoadingView: View {
    @ObservedObject private var state: OnboardingState
    private let wheelNamespace: Namespace.ID?
    @State private var isSpinning = false

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

                Text("为你计算生辰八字中…")
                    .font(AppFonts.small)
                    .foregroundStyle(AppColors.neutralGray)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            isSpinning = true
        }
    }
}

#Preview {
    OnboardingLoadingView(state: OnboardingState())
}
