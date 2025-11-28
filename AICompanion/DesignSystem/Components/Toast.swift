import SwiftUI

// MARK: - Toast Type

public enum ToastType {
    case success
    case error
    case info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return AppColors.neoGreen
        case .error: return AppColors.neoRed
        case .info: return AppColors.neoPurple
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .success: return AppColors.bgMint
        case .error: return AppColors.lightRed
        case .info: return AppColors.bgLavender
        }
    }
}

// MARK: - Toast Data

public struct ToastData: Identifiable, Equatable {
    public let id = UUID()
    public let message: String
    public let type: ToastType

    public init(message: String, type: ToastType = .info) {
        self.message = message
        self.type = type
    }
}

// MARK: - Toast View

public struct ToastView: View {
    let toast: ToastData

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(toast.type.color)

            Text(toast.message)
                .font(AppFonts.body)
                .foregroundColor(AppColors.neoBlack)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(toast.type.backgroundColor)
        .cornerRadius(NeoBrutal.radiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: NeoBrutal.radiusMedium)
                .stroke(AppColors.neoBlack, lineWidth: NeoBrutal.borderNormal)
        )
        .shadow(color: AppColors.shadowColor, radius: 0, x: 4, y: 4)
        .padding(.horizontal, 24)
    }
}

// MARK: - Toast Modifier

public struct ToastModifier: ViewModifier {
    @Binding var toast: ToastData?
    let duration: Double

    public func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if let toastData = toast {
                VStack {
                    ToastView(toast: toastData)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    toast = nil
                                }
                            }
                        }
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.3)) {
                                toast = nil
                            }
                        }
                        .padding(.top, 50)

                    Spacer()
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toast)
            }
        }
    }
}

// MARK: - View Extension

public extension View {
    func toast(_ toast: Binding<ToastData?>, duration: Double = 3.0) -> some View {
        modifier(ToastModifier(toast: toast, duration: duration))
    }
}
