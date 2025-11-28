import SwiftUI

// MARK: - Finch-Inspired Dialog with 3D Buttons
public struct AppDialog: View {
    @Binding private var isPresented: Bool
    private let message: String
    private let title: String?
    private let primaryTitle: String
    private let primaryAction: () -> Void
    private let secondaryTitle: String?
    private let secondaryAction: (() -> Void)?
    
    // Button press states for 3D effect
    @State private var isPrimaryPressed = false
    @State private var isSecondaryPressed = false

    public init(
        isPresented: Binding<Bool>,
        message: String,
        primaryTitle: String,
        primaryAction: @escaping () -> Void,
        secondaryTitle: String? = nil,
        secondaryAction: (() -> Void)? = nil,
        title: String? = nil
    ) {
        self._isPresented = isPresented
        self.message = message
        self.title = title
        self.primaryTitle = primaryTitle
        self.primaryAction = primaryAction
        self.secondaryTitle = secondaryTitle
        self.secondaryAction = secondaryAction
    }

    public var body: some View {
        if isPresented {
            ZStack {
                // Full screen mask overlay
                Color.black.opacity(0.4)
                    .ignoresSafeArea(.all)
                    .onTapGesture {
                        // Dismiss on background tap (optional)
                    }

                VStack(spacing: 0) {
                    // Finch-style: Soft title with gentle background
                    if let title {
                        Text(title)
                            .font(AppFonts.cuteHeadline)
                            .foregroundStyle(AppColors.textDark)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(AppColors.bgPinkLight)
                    }

                    VStack(spacing: 24) {
                        Text(message)
                            .font(AppFonts.body)
                            .foregroundStyle(AppColors.textDark)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 4)

                        HStack(spacing: 12) {
                            // Secondary button (Finch 3D outlined style)
                            if let secondaryTitle, let secondaryAction {
                                Button(action: {
                                    isPresented = false
                                    secondaryAction()
                                }) {
                                    ZStack {
                                        // Depth layer
                                        RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                                            .fill(AppColors.textLight.opacity(0.5))
                                            .offset(y: isSecondaryPressed ? 1 : 3)
                                        
                                        // Main button face
                                        RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                                            .fill(AppColors.cardWhite)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                                                    .stroke(AppColors.primary.opacity(0.4), lineWidth: 1.5)
                                            )
                                            .offset(y: isSecondaryPressed ? 2 : 0)
                                        
                                        Text(secondaryTitle)
                                            .font(AppFonts.cuteButton)
                                            .foregroundStyle(AppColors.primary)
                                            .offset(y: isSecondaryPressed ? 2 : 0)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                }
                                .buttonStyle(.plain)
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            withAnimation(.finchPress) { isSecondaryPressed = true }
                                        }
                                        .onEnded { _ in
                                            withAnimation(.finchPress) { isSecondaryPressed = false }
                                        }
                                )
                            }

                            // Primary button (Finch 3D filled style)
                            Button(action: {
                                isPresented = false
                                primaryAction()
                            }) {
                                ZStack {
                                    // Depth layer
                                    RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                                        .fill(AppColors.primaryDepth)
                                        .offset(y: isPrimaryPressed ? 1 : 3)
                                    
                                    // Main button face
                                    RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                                        .fill(AppColors.primary)
                                        .offset(y: isPrimaryPressed ? 2 : 0)
                                    
                                    Text(primaryTitle)
                                        .font(AppFonts.cuteButton)
                                        .foregroundStyle(.white)
                                        .offset(y: isPrimaryPressed ? 2 : 0)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in
                                        withAnimation(.finchPress) { isPrimaryPressed = true }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.finchPress) { isPrimaryPressed = false }
                                    }
                            )
                        }
                    }
                    .padding(24)
                }
                .background(AppColors.cardWhite)
                .cornerRadius(CuteClean.radiusLarge)
                .shadow(color: AppColors.shadowColor, radius: 20, x: 0, y: 8)
                .padding(.horizontal, 32)
            }
            .zIndex(1000) // Ensure dialog is on top
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .animation(.finchSmooth, value: isPresented)
        }
    }
}
