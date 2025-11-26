import SwiftUI
import Combine

public struct ChatView: View {
    private let userId: Int
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ChatViewModel
    
    @State private var keyboardHeight: CGFloat = 0
    
    // Scroll state
    @State private var scrollProxy: ScrollViewProxy? = nil
    private let loadingIndicatorId = "loading-indicator"
    
    public init(userId: Int) {
        self.userId = userId
        self._viewModel = StateObject(wrappedValue: ChatViewModel(userId: userId))
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let containerWidth = geometry.size.width - 48
            
            ZStack(alignment: .top) {
                AppColors.gradientBackground
                    .ignoresSafeArea()
                
                Image("star_bg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .opacity(0.6)
                
                VStack(spacing: 0) {
                    ChatHeader()
                    
                    // White card container matching OnboardingScaffold style
                    ZStack(alignment: .top) {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)
                        
                        if viewModel.isInitialLoading {
                            // Loading state while fetching greeting
                            VStack(spacing: 16) {
                                Spacer()
                                ProgressView()
                                    .tint(AppColors.purple)
                                Text("正在加载...")
                                    .font(AppFonts.body)
                                    .foregroundStyle(AppColors.textBlack)
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 16) {
                                ScrollViewReader { proxy in
                                    ScrollView {
                                        LazyVStack(spacing: 12) {
                                            // Load more button at top
                                            if viewModel.hasMoreHistory {
                                                Button(action: viewModel.loadMoreHistory) {
                                                    if viewModel.isLoadingHistory {
                                                        ProgressView()
                                                            .tint(AppColors.purple)
                                                    } else {
                                                        Text("加载更多")
                                                            .font(AppFonts.caption)
                                                            .foregroundStyle(AppColors.purple)
                                                    }
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .disabled(viewModel.isLoadingHistory)
                                            }
                                            
                                            ForEach(viewModel.messages) { message in
                                                if message.isDivider {
                                                    ChatDateDivider(date: message.createdAt)
                                                        .id(message.id)
                                                } else {
                                                    ChatBubble(message: message)
                                                        .id(message.id)
                                                }
                                            }
                                            
                                            if viewModel.isSending {
                                                HStack {
                                                    ChatBubbleLoadingIndicator(
                                                        isActive: $viewModel.isSending,
                                                        subtitle: nil
                                                    )
                                                    Spacer()
                                                }
                                                .id(loadingIndicatorId)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    .onChange(of: viewModel.messages.count) { _, _ in
                                        scrollToBottom(proxy: proxy)
                                    }
                                    .onChange(of: viewModel.isSending) { _, newValue in
                                        if newValue {
                                            // Scroll to loading indicator when sending starts
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                withAnimation {
                                                    proxy.scrollTo(loadingIndicatorId, anchor: .bottom)
                                                }
                                            }
                                        }
                                    }
                                    .onAppear {
                                        scrollProxy = proxy
                                    }
                                }
                                
                                if let errorText = viewModel.errorText {
                                    Text(errorText)
                                        .font(AppFonts.caption)
                                        .foregroundStyle(AppColors.accentRed)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                ChatInputArea(
                                    draftMessage: $viewModel.draftMessage,
                                    inputMode: $viewModel.inputMode,
                                    isSending: viewModel.isSending,
                                    onSend: { viewModel.sendCurrentMessage() },
                                    onVoiceComplete: { text in viewModel.sendMessage(text) },
                                    onToggleInputMode: { viewModel.toggleInputMode() }
                                )
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                        }
                    }
                    .frame(width: containerWidth)
                    .frame(maxHeight: .infinity)
                    .padding(.bottom, 28)
                }
            }
        }
        .padding(.bottom, keyboardHeight)
        .animation(.easeOut(duration: 0.25), value: keyboardHeight)
        .onAppear(perform: viewModel.loadInitialHistory)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UIKeyboardWillShowNotification"))) { notification in
            if let frameValue = notification.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? NSValue {
                keyboardHeight = frameValue.cgRectValue.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UIKeyboardWillHideNotification"))) { _ in
            keyboardHeight = 0
        }
        .navigationBarHidden(true)
        .toast($viewModel.toast)
        .alert("需要权限", isPresented: $viewModel.showPermissionAlert) {
            Button("允许") {
                Task {
                    await viewModel.requestPermissionAndExecute()
                }
            }
            Button("取消", role: .cancel) {
                viewModel.handlePermissionAlertCancel()
            }
        } message: {
            if let type = viewModel.permissionType {
                Text(type.contextMessage)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = viewModel.messages.last?.id {
            withAnimation {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}

#Preview {
    ChatView(userId: 1)
}
