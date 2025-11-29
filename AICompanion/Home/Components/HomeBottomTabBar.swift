import SwiftUI

// MARK: - Home Tab Enum

/// Tabs available in the home screen
enum HomeTab {
    case daily
    case goals
    case fortune
    case personality
    case settings
}

// MARK: - Home Bottom Tab Bar

/// Bottom tab bar for the home screen
struct HomeBottomTabBar: View {
    @Binding var selectedTab: HomeTab
    
    var body: some View {
        HStack(spacing: 8) {
            tabItem(icon: "checkmark.circle.fill", label: "每日待办", tab: .daily)
            tabItem(icon: "target", label: "目标追踪", tab: .goals)
            // Hidden for now - feature not ready
            // tabItem(icon: "sparkles", label: "流年推测", tab: .fortune)
            // tabItem(icon: "person.crop.circle", label: "性格密码", tab: .personality)
            tabItem(icon: "gearshape.fill", label: "设置", tab: .settings)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(AppColors.cardWhite)
        .shadow(color: AppColors.shadowColor, radius: 6, x: 0, y: -2)
    }
    
    // MARK: - Tab Item
    
    private func tabItem(icon: String, label: String, tab: HomeTab) -> some View {
        let isActive = selectedTab == tab

        return Button(action: {
            withAnimation(.easeOut(duration: CuteClean.animationQuick)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(isActive ? AppColors.primary : AppColors.textMedium)

                Text(label)
                    .font(AppFonts.caption)
                    .foregroundStyle(isActive ? AppColors.primary : AppColors.textLight)
                
                // Finch-style pill indicator
                Capsule()
                    .fill(isActive ? AppColors.primary : Color.clear)
                    .frame(width: 24, height: 4)
                    .offset(y: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
