import SwiftUI

public struct GenderChip: View {
    public struct Style {
        public let isSelected: Bool
        public init(isSelected: Bool) { self.isSelected = isSelected }
    }

    private let text: String
    private let isSelected: Bool
    private let action: () -> Void

    public init(_ text: String, isSelected: Bool, action: @escaping () -> Void) {
        self.text = text
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(text)
                .font(AppFonts.small)
                .foregroundStyle(isSelected ? Color.white : AppColors.textBlack)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? AppColors.purple : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : AppColors.textBlack, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
