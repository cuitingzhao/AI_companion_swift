import Foundation
import EventKit
import HealthKit

// MARK: - Permission Types

public enum PermissionType: String, CaseIterable {
    case calendar = "calendar_manager"
    case health = "health_data"
    case screenTime = "screen_time"
    // alarm_manager uses URL scheme, no permission needed
    
    var displayName: String {
        switch self {
        case .calendar: return "日历"
        case .health: return "健康数据"
        case .screenTime: return "屏幕使用时间"
        }
    }
    
    var contextMessage: String {
        switch self {
        case .calendar: return "为了帮你管理日程，需要访问你的日历"
        case .health: return "为了帮你查看健康数据，需要访问健康应用"
        case .screenTime: return "为了帮你查看屏幕使用情况，需要访问屏幕使用时间"
        }
    }
    
    var denialMessage: String {
        switch self {
        case .calendar: return "没关系，你也可以在系统日历中手动查看和管理日程"
        case .health: return "没关系，你也可以在健康应用中查看相关数据"
        case .screenTime: return "没关系，你也可以在设置中查看屏幕使用时间"
        }
    }
}

public enum PermissionStatus {
    case notDetermined
    case authorized
    case denied
    case restricted
}

// MARK: - Permission Manager

public final class PermissionManager {
    public static let shared = PermissionManager()
    
    private let eventStore = EKEventStore()
    private let healthStore: HKHealthStore? = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
    
    // Cache permission status to avoid repeated checks
    private var cachedStatus: [PermissionType: PermissionStatus] = [:]
    
    private init() {}
    
    // MARK: - Public API
    
    /// Get permission type for a tool name
    public func permissionType(for tool: String) -> PermissionType? {
        return PermissionType(rawValue: tool)
    }
    
    /// Check if a tool requires permission (alarm_manager doesn't)
    public func requiresPermission(tool: String) -> Bool {
        return permissionType(for: tool) != nil
    }
    
    /// Check current permission status
    public func checkStatus(for type: PermissionType) -> PermissionStatus {
        if let cached = cachedStatus[type] {
            return cached
        }
        
        let status: PermissionStatus
        switch type {
        case .calendar:
            status = checkCalendarStatus()
        case .health:
            status = checkHealthStatus()
        case .screenTime:
            // Screen Time API requires iOS 15+ and has limited availability
            status = .notDetermined
        }
        
        cachedStatus[type] = status
        return status
    }
    
    /// Request permission with async/await
    public func requestPermission(for type: PermissionType) async -> PermissionStatus {
        switch type {
        case .calendar:
            return await requestCalendarPermission()
        case .health:
            return await requestHealthPermission()
        case .screenTime:
            // Screen Time requires special entitlements
            return .denied
        }
    }
    
    /// Clear cached status (call after settings change)
    public func clearCache() {
        cachedStatus.removeAll()
    }
    
    // MARK: - Calendar Permission
    
    private func checkCalendarStatus() -> PermissionStatus {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorized, .fullAccess:
            return .authorized
        case .denied:
            return .denied
        case .restricted, .writeOnly:
            return .restricted
        @unknown default:
            return .notDetermined
        }
    }
    
    private func requestCalendarPermission() async -> PermissionStatus {
        do {
            if #available(iOS 17.0, *) {
                let granted = try await eventStore.requestFullAccessToEvents()
                let status: PermissionStatus = granted ? .authorized : .denied
                cachedStatus[.calendar] = status
                return status
            } else {
                let granted = try await eventStore.requestAccess(to: .event)
                let status: PermissionStatus = granted ? .authorized : .denied
                cachedStatus[.calendar] = status
                return status
            }
        } catch {
            print("❌ Calendar permission error: \(error)")
            cachedStatus[.calendar] = .denied
            return .denied
        }
    }
    
    // MARK: - Health Permission
    
    private func checkHealthStatus() -> PermissionStatus {
        guard healthStore != nil else { return .restricted }
        // HealthKit doesn't have a simple "check all" status
        // We return notDetermined and request when needed
        return .notDetermined
    }
    
    private func requestHealthPermission() async -> PermissionStatus {
        guard let healthStore = healthStore else {
            return .restricted
        }
        
        // Define the types we want to read
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            cachedStatus[.health] = .authorized
            return .authorized
        } catch {
            print("❌ Health permission error: \(error)")
            cachedStatus[.health] = .denied
            return .denied
        }
    }
}
