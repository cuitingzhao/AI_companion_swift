import SwiftUI

public struct OnboardingScaffold<Header: View, Content: View>: View {
    private let header: () -> Header
    private let content: () -> Content
    private let topSpacing: CGFloat
    private let containerColor: Color
    private let isCentered: Bool
    private let verticalPadding: CGFloat

    public init(topSpacing: CGFloat = 140,
                containerColor: Color = Color.white,
                isCentered: Bool = false,
                verticalPadding: CGFloat = 20,
                @ViewBuilder header: @escaping () -> Header = { EmptyView() },
                @ViewBuilder content: @escaping () -> Content) {
        self.topSpacing = topSpacing
        self.containerColor = containerColor
        self.isCentered = isCentered
        self.verticalPadding = verticalPadding
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
                    // .scaledToFill()
                    .ignoresSafeArea()
                    .opacity(0.6)

                header()
                    .padding(.top, 32)

                VStack {
                    if isCentered {
                        // Geometric vertical centering: symmetric spacers
                        Spacer()

                        ZStack(alignment: .center) {
                            RoundedRectangle(cornerRadius: 28)
                                .fill(containerColor)
                                .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)

                            VStack(spacing: 24) {
                                content()
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal, 24)
                            .padding(.vertical, verticalPadding)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: containerWidth)
                        .padding(.bottom, 28)

                        Spacer()
                    } else {
                        Spacer(minLength: topSpacing)

                        ZStack(alignment: .top) {
                            RoundedRectangle(cornerRadius: 28)
                                .fill(containerColor)
                                .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)

                            VStack(spacing: 24) {
                                content()
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, verticalPadding)
                        }
                        .frame(width: containerWidth)
                        .padding(.bottom, 28)
                    }
                }
            }
        }
    }
}

#Preview {
    OnboardingScaffold(
        topSpacing: 80,
        containerColor: AppColors.cardWhite,
        header: {
            Text("Onboarding Header")
                .font(AppFonts.title)
                .foregroundStyle(AppColors.textBlack)
        },
        content: {
            VStack(spacing: 16) {
                Text("Preview content")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textMedium)
                Text("用于预览 OnboardingScaffold 布局")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textLight)
            }
        }
    )
}
