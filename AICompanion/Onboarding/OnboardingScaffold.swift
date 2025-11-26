import SwiftUI

public struct OnboardingScaffold<Header: View, Content: View>: View {
    private let header: () -> Header
    private let content: () -> Content
    private let topSpacing: CGFloat
    private let containerColor: Color

    public init(topSpacing: CGFloat = 140,
                containerColor: Color = Color.white,
                @ViewBuilder header: @escaping () -> Header = { EmptyView() },
                @ViewBuilder content: @escaping () -> Content) {
        self.topSpacing = topSpacing
        self.containerColor = containerColor
        self.header = header
        self.content = content
    }

    public var body: some View {
        GeometryReader { geometry in
            let containerWidth = geometry.size.width - 48

            ZStack(alignment: .top) {
                AppColors.gradientBackground
                    .ignoresSafeArea()

                Image("star_bg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .opacity(0.6)

                header()
                    .padding(.top, 32)

                VStack {
                    Spacer(minLength: topSpacing)

                    ZStack(alignment: .top) {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(containerColor)
                            .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)

                        VStack(spacing: 24) {
                            content()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                    }
                    .frame(width: containerWidth)
                    .padding(.bottom, 28)
                }
            }
        }
    }
}
