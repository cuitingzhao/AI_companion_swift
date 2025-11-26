import SwiftUI

public struct FloatingChatButton: View {
    private let action: () -> Void
    @State private var isPulsing: Bool = false

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                // Outer glow effect
                Circle()
                    .fill(AppColors.purple.opacity(0.3))
                    .frame(width: 72, height: 72)
                    .scaleEffect(isPulsing ? 1.15 : 1.0)
                    .blur(radius: 8)

                // Main button
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppColors.purple.opacity(0.85),
                                AppColors.purple
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: AppColors.purple.opacity(0.4), radius: 12, x: 0, y: 6)

                // Icon
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    ZStack {
        AppColors.gradientBackground
            .ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingChatButton(action: {})
                    .padding(.trailing, 24)
                    .padding(.bottom, 100)
            }
        }
    }
}
