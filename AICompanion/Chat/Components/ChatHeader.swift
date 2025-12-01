import SwiftUI

// MARK: - Cute Clean Chat Header
struct ChatHeader: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack(spacing: 16) {
            // Cute Clean: Circular back button with soft shadow
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.cutePink)
                    .frame(width: 40, height: 40)
                    .background(AppColors.bgCream)
                    .clipShape(Circle())
                    .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 4)
    }
}
