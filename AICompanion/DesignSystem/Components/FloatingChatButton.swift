import SwiftUI

// MARK: - Finch-Inspired Floating Chat Button (3D Style)
public struct FloatingChatButton: View {
    private let action: () -> Void
    @State private var isPressed: Bool = false
    @State private var isPulsing: Bool = false

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                // Finch 3D: Depth layer
                Circle()
                    .fill(AppColors.primaryDepth)
                    .frame(width: 60, height: 60)
                    .offset(y: isPressed ? 2 : 5)
                
                // Main button face
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 60, height: 60)
                    .offset(y: isPressed ? 3 : 0)

                // Icon - friendly chat bubble
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white)
                    .offset(y: isPressed ? 3 : 0)
            }
            .scaleEffect(isPulsing ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeOut(duration: CuteClean.animationQuick)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: CuteClean.animationQuick)) {
                        isPressed = false
                    }
                }
        )
        .onAppear {
            // Gentle pulse animation to draw attention
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    ZStack {
        AppColors.bgCream
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
