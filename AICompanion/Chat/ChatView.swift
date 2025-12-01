import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

public struct ChatView: View {
    private let userId: Int
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var viewModel: ChatViewModel
    
    @State private var keyboardHeight: CGFloat = 0
    
    // Scroll state
    @State private var scrollProxy: ScrollViewProxy? = nil
    private let loadingIndicatorId = "loading-indicator"
    
    /// Initialize with a pre-warmed viewModel for faster loading
    init(viewModel: ChatViewModel) {
        self.userId = viewModel.userId
        self.viewModel = viewModel
    }
    
    /// Initialize with userId - creates a new viewModel
    public init(userId: Int) {
        self.userId = userId
        self.viewModel = ChatViewModel(userId: userId)
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            
            ZStack(alignment: .top) {
                // Finch-inspired: Warm cream to light sage gradient
                // LinearGradient(
                //     colors: [AppColors.bgCream, AppColors.bgSageLight],
                //     startPoint: .top,
                //     endPoint: .bottom
                // )
                // .ignoresSafeArea()                
                AppColors.accentYellow
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ChatHeader()
                    
                    // Finch-inspired: Clean content area
                    ZStack(alignment: .top) {
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
                                        // Single scroll handler for all message changes
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
                                        // Scroll to bottom on appear (handles pre-warmed case)
                                        if !viewModel.isInitialLoading {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                scrollToBottom(proxy: proxy)
                                            }
                                        }
                                    }
                                    .onChange(of: viewModel.isInitialLoading) { _, isLoading in
                                        // Scroll to bottom when initial loading completes
                                        if !isLoading {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                scrollToBottom(proxy: proxy)
                                            }
                                        }
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
                                    selectedImages: $viewModel.selectedImages,
                                    isSending: viewModel.isSending,
                                    onSend: { viewModel.sendCurrentMessage() },
                                    onVoiceComplete: { text in viewModel.sendMessage(text) },
                                    onToggleInputMode: { viewModel.toggleInputMode() },
                                    onAddImage: { image in viewModel.addImage(image) },
                                    onRemoveImage: { index in viewModel.removeImage(at: index) },
                                    onClearImages: { viewModel.clearImages() }
                                )
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 14)
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.bottom, keyboardHeight > 0 ? max(keyboardHeight - safeAreaBottom, 0) + 8 : 28)
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .animation(.easeOut(duration: 0.25), value: keyboardHeight)
        .onAppear(perform: viewModel.loadInitialHistory)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            guard let userInfo = notification.userInfo,
                  let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return
            }
            keyboardHeight = frameValue.height
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
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
        .fullScreenCover(isPresented: $viewModel.showGoalWizard) {
            GoalWizardView(
                userId: viewModel.userId,
                candidateDescription: viewModel.goalWizardDescription,
                source: viewModel.goalWizardSource,
                onDismiss: {
                    viewModel.showGoalWizard = false
                }
            )
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
