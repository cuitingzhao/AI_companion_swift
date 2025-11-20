import SwiftUI
import Combine

public struct ChatBubbleLoadingIndicator: View {
    @Binding private var isActive: Bool
    private let subtitle: String?
    @State private var dotsStep: Int = 0

    public init(isActive: Binding<Bool>, subtitle: String? = nil) {
        self._isActive = isActive
        self.subtitle = subtitle
    }

    public var body: some View {
        let dotsCount = (dotsStep % 3) + 3 // cycles through 3,4,5 dots
        let dots = String(repeating: ".", count: dotsCount)

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(AppColors.purple)

                Text(dots)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textBlack)
            }

            if let subtitle {
                Text(subtitle)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textBlack)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(18)
        .onAppear {
            dotsStep = 0
        }
        .onReceive(Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()) { _ in
            guard isActive else { return }
            dotsStep += 1
        }
    }
}
