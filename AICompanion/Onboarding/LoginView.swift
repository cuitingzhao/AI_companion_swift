import SwiftUI
import UIKit

/// Login/Register view for SMS verification
/// Used for:
/// 1. Guest users who need to bind phone number
/// 2. New users who want to login before onboarding
/// 3. Existing users who want to login
public struct LoginView: View {
    @ObservedObject private var state: OnboardingState
    private let onLoginSuccess: (Bool) -> Void  // Bool indicates if this is a new user
    private let onSkip: (() -> Void)?
    private let onBack: (() -> Void)?
    
    @State private var phoneNumber: String = ""
    @State private var verificationCode: String = ""
    @State private var isCodeSent: Bool = false
    @State private var countdown: Int = 0
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var countdownTimer: Timer?
    
    // Whether this is a guest user binding phone (vs new login)
    private var isGuestBinding: Bool {
        AuthManager.shared.isGuest && AuthManager.shared.hasStoredToken
    }
    
    public init(
        state: OnboardingState,
        onLoginSuccess: @escaping (Bool) -> Void,
        onSkip: (() -> Void)? = nil,
        onBack: (() -> Void)? = nil
    ) {
        self.state = state
        self.onLoginSuccess = onLoginSuccess
        self.onSkip = onSkip
        self.onBack = onBack
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            OnboardingScaffold(
                topSpacing: 80,
                containerColor: AppColors.accentYellow.opacity(0.8),
                isCentered: true,
                verticalPadding: 48,
                header: {
                    VStack(spacing: 8) {
                        GIFImage(name: "winking")
                            .frame(width: 180, height: 100)
                        
                        Text(isGuestBinding ? "绑定手机号" : "登录/注册")
                            .font(AppFonts.subtitle)
                            .foregroundStyle(AppColors.textBlack)
                    }
                }
            ) {
            VStack(alignment: .center, spacing: 24) {
                // Description text
                Text(isGuestBinding 
                     ? "绑定手机号后，你的数据将被安全保存，换设备也能找回"
                     : "使用手机号登录或注册")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textMedium)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
                
                // Phone number input
                VStack(alignment: .leading, spacing: 8) {
                    Text("手机号")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.neutralGray)
                    
                    HStack(spacing: 12) {
                        Text("+86")
                            .font(AppFonts.body)
                            .foregroundStyle(AppColors.textBlack)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(CuteClean.radiusMedium)
                        
                        TextField("请输入手机号", text: $phoneNumber)
                            .font(AppFonts.body)
                            .keyboardType(.phonePad)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(CuteClean.radiusMedium)
                            .onChange(of: phoneNumber) { _, newValue in
                                // Only allow digits, max 11
                                phoneNumber = String(newValue.filter { $0.isNumber }.prefix(11))
                            }
                    }
                }
                .frame(maxWidth: 280)
                
                // Verification code section (shown after SMS sent)
                if isCodeSent {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("验证码")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.neutralGray)
                        
                        HStack(spacing: 12) {
                            TextField("请输入验证码", text: $verificationCode)
                                .font(AppFonts.body)
                                .keyboardType(.numberPad)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color.white)
                                .cornerRadius(CuteClean.radiusMedium)
                                .onChange(of: verificationCode) { _, newValue in
                                    // Only allow digits, max 6
                                    verificationCode = String(newValue.filter { $0.isNumber }.prefix(6))
                                }
                            
                            Button(action: { Task { await sendSMS() } }) {
                                Text(countdown > 0 ? "\(countdown)s" : "重新发送")
                                    .font(AppFonts.small)
                                    .foregroundStyle(countdown > 0 ? AppColors.neutralGray : AppColors.primary)
                            }
                            .disabled(countdown > 0 || isLoading)
                        }
                    }
                    .frame(maxWidth: 280)
                }
                
                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.accentCoral)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    if isCodeSent {
                        // Verify button
                        Button(action: { Task { await verifyCode() } }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("验证并登录")
                                }
                            }
                            .font(AppFonts.cuteButton)
                            .foregroundStyle(.white)
                            .frame(maxWidth: 280)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                                    .fill(canVerify ? AppColors.primary : AppColors.primary.opacity(0.4))
                            )
                            .shadow(color: AppColors.shadowColor, radius: 6, x: 0, y: 6)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canVerify || isLoading)
                    } else {
                        // Send SMS button
                        Button(action: { Task { await sendSMS() } }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("获取验证码")
                                }
                            }
                            .font(AppFonts.cuteButton)
                            .foregroundStyle(.white)
                            .frame(maxWidth: 280)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                                    .fill(isPhoneValid ? AppColors.primary : AppColors.primary.opacity(0.4))
                            )
                            .shadow(color: AppColors.shadowColor, radius: 6, x: 0, y: 6)
                        }
                        .buttonStyle(.plain)
                        .disabled(!isPhoneValid || isLoading)
                    }
                    
                    // Skip button (only for guest users)
                    if isGuestBinding, let skip = onSkip {
                        Button(action: skip) {
                            Text("暂时跳过")
                                .font(AppFonts.small)
                                .foregroundStyle(AppColors.neutralGray)
                                .underline()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .onDisappear {
            countdownTimer?.invalidate()
        }
            
            // Back button (only shown if onBack is provided)
            if let back = onBack {
                Button(action: back) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.primary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.bgCream)
                        .clipShape(Circle())
                        .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .padding(.leading, 24)
                .padding(.top, 60)  // Account for safe area
            }
        }
    }
    
    // MARK: - Validation
    
    private var isPhoneValid: Bool {
        // Chinese phone number: 11 digits starting with 1
        phoneNumber.count == 11 && phoneNumber.hasPrefix("1")
    }
    
    private var canVerify: Bool {
        isPhoneValid && verificationCode.count == 6
    }
    
    // MARK: - Actions
    
    private func sendSMS() async {
        guard isPhoneValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await AuthAPI.shared.sendSMS(phone: phoneNumber)
            
            if response.success {
                isCodeSent = true
                startCountdown(from: 60)
            } else {
                if let retryAfter = response.retryAfter {
                    errorMessage = response.message
                    startCountdown(from: retryAfter)
                    isCodeSent = true  // Still show code input
                } else {
                    errorMessage = response.message
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func verifyCode() async {
        guard canVerify else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Get device info
            let deviceInfo = UIDevice.current.name
            
            // If guest user, include current token for binding
            let currentToken: String? = isGuestBinding ? await AuthManager.shared.getAccessToken() : nil
            
            let response = try await AuthAPI.shared.verifySMS(
                phone: phoneNumber,
                code: verificationCode,
                deviceInfo: deviceInfo,
                accessToken: currentToken
            )
            
            // Save new tokens
            await AuthManager.shared.saveTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                expiresIn: response.expiresIn
            )
            
            // Update state
            state.submitUserId = response.user.id
            state.nickname = response.user.nickname
            
            // Notify success
            onLoginSuccess(response.isNewUser)
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func startCountdown(from seconds: Int) {
        countdown = seconds
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer.invalidate()
            }
        }
    }
}

#Preview("Login - New User") {
    LoginView(
        state: OnboardingState(),
        onLoginSuccess: { _ in },
        onSkip: nil,
        onBack: { }
    )
}

#Preview("Login - Guest Binding") {
    LoginView(
        state: OnboardingState(),
        onLoginSuccess: { _ in },
        onSkip: { },
        onBack: nil
    )
}
