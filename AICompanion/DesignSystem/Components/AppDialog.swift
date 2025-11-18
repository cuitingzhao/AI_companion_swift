import SwiftUI

public struct AppDialog: View {
    @Binding private var isPresented: Bool
    private let message: String
    private let title: String?
    private let primaryTitle: String
    private let primaryAction: () -> Void
    private let secondaryTitle: String?
    private let secondaryAction: (() -> Void)?

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
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if let title {
                        Text(title)
                            .font(AppFonts.body)
                            .foregroundStyle(AppColors.textBlack)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppColors.purple.opacity(0.06))
                    }

                    VStack(spacing: 16) {
                        Text(message)
                            .font(AppFonts.small)
                            .foregroundStyle(AppColors.textBlack)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)

                        HStack(spacing: 12) {
                            if let secondaryTitle, let secondaryAction {
                                Button(action: {
                                    isPresented = false
                                    secondaryAction()
                                }) {
                                    Text(secondaryTitle)
                                        .font(AppFonts.body)
                                        .foregroundStyle(AppColors.purple)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                            }

                            Button(action: {
                                isPresented = false
                                primaryAction()
                            }) {
                                Text(primaryTitle)
                                    .font(AppFonts.body)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(AppColors.purple)
                                    .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
                .padding(.horizontal, 40)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: isPresented)
        }
    }
}
