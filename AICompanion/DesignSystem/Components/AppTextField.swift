import SwiftUI

// MARK: - Cute Clean Text Field
public struct AppTextField<Accessory: View>: View {
    private let title: String
    private let text: Binding<String>
    private let accessory: Accessory
    private let submitLabel: SubmitLabel?
    private let onSubmit: (() -> Void)?

    public init(
        _ title: String,
        text: Binding<String>,
        submitLabel: SubmitLabel? = nil,
        onSubmit: (() -> Void)? = nil,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.title = title
        self.text = text
        self.accessory = accessory()
        self.submitLabel = submitLabel
        self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: 12) {
            TextField("", text: text)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textDark)
                .placeholder(when: text.wrappedValue.isEmpty) {
                    Text(title)
                        .foregroundStyle(AppColors.textLight)
                        .font(AppFonts.body)
                }
                .submitLabel(submitLabel ?? .done)
                .onSubmit {
                    onSubmit?()
                }

            accessory
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(AppColors.bgCream)
        .cornerRadius(CuteClean.radiusMedium)
        // Cute Clean: No shadow, subtle border only
        .overlay(
            RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                .stroke(AppColors.cutePink.opacity(0.2), lineWidth: 1)
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
