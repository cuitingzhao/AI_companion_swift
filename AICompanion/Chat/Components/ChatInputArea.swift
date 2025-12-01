import SwiftUI
import PhotosUI
import UIKit

// MARK: - Cute Clean Chat Input Area
struct ChatInputArea: View {
    @Binding var draftMessage: String
    @Binding var inputMode: ChatViewInputMode
    @Binding var selectedImages: [UIImage]
    let isSending: Bool
    let onSend: () -> Void
    let onVoiceComplete: (String) -> Void
    let onToggleInputMode: () -> Void
    let onAddImage: (UIImage) -> Void
    let onRemoveImage: (Int) -> Void
    let onClearImages: () -> Void
    
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showImageSourceSheet: Bool = false
    @State private var showCamera: Bool = false
    @State private var showPhotoPicker: Bool = false
    
    // Only allow 1 image per message
    private var canAddImage: Bool {
        inputMode == .text && selectedImages.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Image preview (single image only)
            if let image = selectedImages.first, inputMode == .text {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColors.neoBlack, lineWidth: 1)
                        )
                    
                    // Remove button
                    Button(action: { onRemoveImage(0) }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                            .background(Circle().fill(AppColors.neoBlack))
                    }
                    .offset(x: 6, y: -6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack(spacing: 12) {
                // Image button (only in text mode)
                if inputMode == .text {
                    Button(action: { showImageSourceSheet = true }) {
                        Image(systemName: "photo")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(canAddImage ? AppColors.neoPurple : AppColors.neutralGray)
                            .frame(width: 44, height: 44)
                            .background(canAddImage ? AppColors.bgMintLight : AppColors.neutralGray.opacity(0.2))
                            .clipShape(Circle())
                            .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
                    }
                    .disabled(!canAddImage)
                }
                
                if inputMode == .text {
                    AppTextField(
                        "请输入内容",
                        text: $draftMessage,
                        submitLabel: SubmitLabel.send,
                        onSubmit: {
                            onSend()
                        }
                    )
                } else {
                    VoiceInputButton(
                        text: $draftMessage,
                        style: .longPress,
                        onComplete: { text in
                            onVoiceComplete(text)
                        }
                    )
                }
                
                // Cute Clean: Circular toggle button with soft colors
                Button(action: {
                    // Clear images when switching to voice mode
                    if inputMode == .text && !selectedImages.isEmpty {
                        onClearImages()
                    }
                    onToggleInputMode()
                }) {
                    Image(systemName: inputMode == .text ? "mic.fill" : "keyboard.fill")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(inputMode == .text ? AppColors.cuteCoral : AppColors.neoPurple)
                        .frame(width: 44, height: 44)
                        .background(inputMode == .text ? AppColors.cutePeach : AppColors.bgMintLight)
                        .clipShape(Circle())
                        .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
                }
            }
        }
        .disabled(isSending)
        .opacity(isSending ? 0.6 : 1)
        .confirmationDialog("选择图片来源", isPresented: $showImageSourceSheet, titleVisibility: .visible) {
            Button("拍照") {
                showCamera = true
            }
            Button("从相册选择") {
                showPhotoPicker = true
            }
            Button("取消", role: .cancel) {}
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem = newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        onAddImage(image)
                    }
                }
                selectedPhotoItem = nil
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                if let image = image {
                    onAddImage(image)
                }
            }
        }
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            parent.onImageCaptured(image)
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onImageCaptured(nil)
            parent.dismiss()
        }
    }
}
