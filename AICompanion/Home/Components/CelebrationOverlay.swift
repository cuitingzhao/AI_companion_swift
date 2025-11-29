import SwiftUI

// MARK: - Celebration Overlay

/// Overlay shown when user completes a task
struct CelebrationOverlay: View {
    @Binding var isShowing: Bool
    
    var body: some View {
        if isShowing {
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Celebration GIF
                    GIFImage(name: "celebrate")
                        .frame(width: 280, height: 280)
                    
                    // Toast message
                    Text("🎉棒棒的，再接再厉！")
                        .font(AppFonts.neoHeadline)
                        .foregroundStyle(AppColors.textBlack)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppColors.neoWhite)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
            .onAppear {
                // Auto-dismiss after GIF plays (approximately 2 seconds)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
        }
    }
}
