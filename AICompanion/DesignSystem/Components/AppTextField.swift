import SwiftUI

public struct AppTextField<Accessory: View>: View {
    private let title: String
    private let text: Binding<String>
    private let accessory: Accessory

    public init(
        _ title: String,
        text: Binding<String>,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.title = title
        self.text = text
        self.accessory = accessory()
    }

    public var body: some View {
        HStack(spacing: 12) {
            TextField(title, text: text)
                .font(AppFonts.small)
                .foregroundStyle(AppColors.textBlack)
                .placeholder(when: text.wrappedValue.isEmpty) {
                    Text(title)
                        .foregroundStyle(AppColors.neutralGray)
                        .font(AppFonts.small)
                }

            accessory
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.textBlack, lineWidth: 1)
        )
    }
}

private extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow {
                content()
            }
            self
        }
    }
}
