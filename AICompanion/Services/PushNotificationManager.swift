import Foundation
import UIKit
import UserNotifications
import Combine

/// Manages push notification registration and token handling
@MainActor
public final class PushNotificationManager: NSObject, ObservableObject {
    public static let shared = PushNotificationManager()
    
    /// The current device push token (hex string)
    @Published public private(set) var deviceToken: String?
    
    /// Whether push notifications are enabled
    @Published public private(set) var isEnabled: Bool = false
    
    /// The user ID to associate with the device token
    private var userId: Int?
    
    /// Whether we've already registered the token with the backend
    private var hasRegisteredWithBackend: Bool = false
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Set the user ID and register token if available
    public func setUserId(_ userId: Int) {
        self.userId = userId
        print("🔔 PushNotificationManager: User ID set to \(userId)")
        
        // If we already have a token, register it now
        if let token = deviceToken, !hasRegisteredWithBackend {
            Task {
                await registerTokenWithBackend(token: token)
            }
        }
    }
    
    /// Request notification permission and register for remote notifications
    public func requestPermissionAndRegister() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isEnabled = granted
                
                if granted {
                    print("🔔 Notification permission granted")
                    UIApplication.shared.registerForRemoteNotifications()
                } else if let error = error {
                    print("❌ Notification permission error: \(error)")
                } else {
                    print("🔔 Notification permission denied")
                }
            }
        }
    }
    
    /// Called when APNs registration succeeds
    public func didRegisterForRemoteNotifications(deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString
        print("🔔 APNs token received: \(tokenString.prefix(20))...")
        
        // Register with backend if we have a user ID
        if let userId = userId, !hasRegisteredWithBackend {
            Task {
                await registerTokenWithBackend(token: tokenString)
            }
        }
    }
    
    /// Called when APNs registration fails
    public func didFailToRegisterForRemoteNotifications(error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }
    
    // MARK: - Private Methods
    
    private func registerTokenWithBackend(token: String) async {
        guard let userId = userId else {
            print("🔔 Cannot register token: no user ID")
            return
        }
        
        do {
            let response = try await NotificationsAPI.shared.registerDeviceToken(userId: userId, pushToken: token)
            hasRegisteredWithBackend = true
            print("🔔 Device token registered with backend: id=\(response.id), active=\(response.isActive)")
        } catch {
            print("❌ Failed to register device token with backend: \(error)")
        }
    }
}

// MARK: - AppDelegate for handling APNs callbacks

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        // Lock orientation to portrait
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in
            PushNotificationManager.shared.didRegisterForRemoteNotifications(deviceToken: deviceToken)
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Task { @MainActor in
            PushNotificationManager.shared.didFailToRegisterForRemoteNotifications(error: error)
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show banner and play sound even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("🔔 Notification tapped: \(userInfo)")
        
        // Handle navigation based on notification type
        if let type = userInfo["type"] as? String {
            switch type {
            case "followup", "reminder", "goal":
                // Could navigate to chat or specific screen
                // For now, just log it
                print("🔔 Notification type: \(type)")
            default:
                break
            }
        }
        
        completionHandler()
    }
}
