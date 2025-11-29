import SwiftUI

// MARK: - Dialog Container

/// A reusable dialog container with dark overlay and white card
struct DialogContainer<Content: View>: View {
    @Binding var isPresented: Bool
    let allowDismissOnTap: Bool
    @ViewBuilder let content: () -> Content
    
    init(
        isPresented: Binding<Bool>,
        allowDismissOnTap: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isPresented = isPresented
        self.allowDismissOnTap = allowDismissOnTap
        self.content = content
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if allowDismissOnTap {
                        isPresented = false
                    }
                }
            
            content()
                .padding(24)
                .background(AppColors.neoWhite)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
                .padding(.horizontal, 32)
        }
    }
}

// MARK: - Dialog Header

/// A reusable dialog header with title and close button
struct DialogHeader: View {
    let title: String
    let onClose: () -> Void
    var isDisabled: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppFonts.neoHeadline)
                .foregroundStyle(AppColors.neoBlack)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.neoBlack)
            }
            .disabled(isDisabled)
        }
    }
}

// MARK: - Labeled Text Field

/// A reusable text field with label
struct LabeledTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var lineLimit: ClosedRange<Int>? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textMedium)
            
            if let lineLimit = lineLimit {
                TextField(placeholder, text: $text, axis: .vertical)
                    .font(AppFonts.body)
                    .lineLimit(lineLimit)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.neutralGray.opacity(0.5), lineWidth: 1)
                    )
            } else {
                TextField(placeholder, text: $text)
                    .font(AppFonts.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.neutralGray.opacity(0.5), lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - Option Picker

/// A reusable horizontal option picker (for priority, status, frequency, etc.)
struct OptionPicker: View {
    let label: String
    let options: [(String, String)] // (value, display)
    @Binding var selectedValue: String
    var onSelectionChange: ((String) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textMedium)
            
            HStack(spacing: 8) {
                ForEach(options, id: \.0) { option in
                    Button(action: {
                        if let onChange = onSelectionChange {
                            onChange(option.0)
                        } else {
                            selectedValue = option.0
                        }
                    }) {
                        Text(option.1)
                            .font(AppFonts.caption)
                            .foregroundStyle(selectedValue == option.0 ? .white : AppColors.textBlack)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedValue == option.0 ? AppColors.neoPurple : AppColors.neutralGray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - Date Toggle Picker

/// A reusable date picker with toggle
struct DateTogglePicker: View {
    let label: String
    @Binding var hasDate: Bool
    @Binding var date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textMedium)
                Spacer()
                Toggle("", isOn: $hasDate)
                    .toggleStyle(RoundKnobToggleStyle())
                    .labelsHidden()
            }
            
            if hasDate {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "zh_CN"))
            }
        }
    }
}

// MARK: - Dialog Button Row

/// A reusable button row for dialogs (Cancel + Save)
struct DialogButtonRow: View {
    let cancelTitle: String
    let saveTitle: String
    let isSaving: Bool
    let isSaveDisabled: Bool
    let onCancel: () -> Void
    let onSave: () -> Void
    
    init(
        cancelTitle: String = "取消",
        saveTitle: String = "保存",
        isSaving: Bool,
        isSaveDisabled: Bool,
        onCancel: @escaping () -> Void,
        onSave: @escaping () -> Void
    ) {
        self.cancelTitle = cancelTitle
        self.saveTitle = saveTitle
        self.isSaving = isSaving
        self.isSaveDisabled = isSaveDisabled
        self.onCancel = onCancel
        self.onSave = onSave
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onCancel) {
                Text(cancelTitle)
                    .font(AppFonts.neoButton)
                    .foregroundStyle(AppColors.neoBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.neoWhite)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.neoBlack, lineWidth: 1)
                    )
            }
            .disabled(isSaving)
            
            Button(action: onSave) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(saveTitle)
                    }
                }
                .font(AppFonts.neoButton)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.neoPurple)
                .cornerRadius(12)
            }
            .disabled(isSaving || isSaveDisabled)
        }
    }
}

// MARK: - Confirmation Dialog

/// A reusable confirmation dialog overlay
struct ConfirmationDialogOverlay: View {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let confirmTitle: String
    let cancelTitle: String
    let onConfirm: () -> Void
    
    init(
        isPresented: Binding<Bool>,
        title: String = "确认",
        message: String,
        confirmTitle: String = "确认",
        cancelTitle: String = "取消",
        onConfirm: @escaping () -> Void
    ) {
        self._isPresented = isPresented
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.cancelTitle = cancelTitle
        self.onConfirm = onConfirm
    }
    
    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Text(title)
                        .font(AppFonts.neoHeadline)
                        .foregroundStyle(AppColors.neoBlack)
                    
                    Text(message)
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textMedium)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            isPresented = false
                        }) {
                            Text(cancelTitle)
                                .font(AppFonts.neoButton)
                                .foregroundStyle(AppColors.neoBlack)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppColors.neoWhite)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppColors.neoBlack, lineWidth: 1)
                                )
                        }
                        
                        Button(action: {
                            onConfirm()
                            isPresented = false
                        }) {
                            Text(confirmTitle)
                                .font(AppFonts.neoButton)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppColors.neoPurple)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
                .padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - Error Message

/// A reusable error message view
struct DialogErrorMessage: View {
    let message: String?
    
    var body: some View {
        if let error = message {
            Text(error)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.accentRed)
        }
    }
}
