import SwiftUI

/// Reusable header component for onboarding screens
public struct OnboardingHeader: View {
    private let imageName: String
    private let imageSize: CGFloat
    private let topPadding: CGFloat
    private let matchedId: String?
    private let namespace: Namespace.ID?
    
    public init(
        imageName: String = "fortune_wheel_small",
        imageSize: CGFloat = 94,
        topPadding: CGFloat = 24,
        matchedId: String? = nil,
        namespace: Namespace.ID? = nil
    ) {
        self.imageName = imageName
        self.imageSize = imageSize
        self.topPadding = topPadding
        self.matchedId = matchedId
        self.namespace = namespace
    }
    
    public var body: some View {
        if let matchedId, let namespace {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: imageSize, height: imageSize)
                .matchedGeometryEffect(id: matchedId, in: namespace)
                .padding(.top, topPadding)
        } else {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: imageSize, height: imageSize)
                .padding(.top, topPadding)
        }
    }
}

#Preview {
    ZStack {
        AppColors.gradientBackground
            .ignoresSafeArea()
        
        OnboardingHeader()
    }
}
