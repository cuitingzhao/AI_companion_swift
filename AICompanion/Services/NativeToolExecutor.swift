import Foundation
import EventKit
import UIKit

// MARK: - Execution Result

public enum NativeToolResult {
    case success(message: String)
    case permissionRequired(type: PermissionType)
    case permissionDenied(fallbackMessage: String)
    case failed(error: String)
}

// MARK: - Native Tool Executor

public final class NativeToolExecutor {
    public static let shared = NativeToolExecutor()
    
    private let permissionManager = PermissionManager.shared
    private let eventStore = EKEventStore()
    
    private init() {}
    
    // MARK: - Public API
    
    /// Execute a pending client action
    public func execute(_ action: PendingClientAction) async -> NativeToolResult {
        print("🔧 Executing native action: \(action.tool).\(action.action)")
        
        switch action.tool {
        case "alarm_manager":
            return await executeAlarmAction(action)
        case "calendar_manager":
            return await executeCalendarAction(action)
        case "health_data":
            return await executeHealthAction(action)
        case "screen_time":
            return await executeScreenTimeAction(action)
        default:
            return .failed(error: "Unknown tool: \(action.tool)")
        }
    }
    
    /// Check if permission is needed before execution
    public func checkPermissionStatus(for action: PendingClientAction) -> PermissionStatus? {
        guard let type = permissionManager.permissionType(for: action.tool) else {
            return nil // No permission needed (e.g., alarm_manager)
        }
        return permissionManager.checkStatus(for: type)
    }
    
    // MARK: - Alarm Manager
    
    private func executeAlarmAction(_ action: PendingClientAction) async -> NativeToolResult {
        // Alarm uses URL scheme - no permission needed
        guard action.action == "create_alarm" else {
            return .failed(error: "Unknown alarm action: \(action.action)")
        }
        
        guard let timeString = action.params["time"]?.value as? String else {
            return .failed(error: "Missing time parameter")
        }
        
        // Parse time (format: "HH:mm")
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return .failed(error: "Invalid time format")
        }
        
        let label = action.params["label"]?.value as? String ?? "闹钟"
        
        // Build Clock app URL
        // Note: iOS doesn't have a direct URL scheme for creating alarms
        // We open the Clock app instead
        guard let url = URL(string: "clock-alarm://") else {
            return .failed(error: "Cannot open Clock app")
        }
        
        await MainActor.run {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Fallback: open Clock app
                if let clockUrl = URL(string: "clock://") {
                    UIApplication.shared.open(clockUrl)
                }
            }
        }
        
        return .success(message: "已打开时钟应用，请手动设置\(String(format: "%02d:%02d", hour, minute))的闹钟「\(label)」")
    }
    
    // MARK: - Calendar Manager
    
    private func executeCalendarAction(_ action: PendingClientAction) async -> NativeToolResult {
        // Check permission first
        let status = permissionManager.checkStatus(for: .calendar)
        
        switch status {
        case .notDetermined:
            return .permissionRequired(type: .calendar)
        case .denied, .restricted:
            return .permissionDenied(fallbackMessage: PermissionType.calendar.denialMessage)
        case .authorized:
            break
        }
        
        switch action.action {
        case "create_event":
            return await createCalendarEvent(action)
        case "query_events":
            return await queryCalendarEvents(action)
        default:
            return .failed(error: "Unknown calendar action: \(action.action)")
        }
    }
    
    private func createCalendarEvent(_ action: PendingClientAction) async -> NativeToolResult {
        guard let title = action.params["title"]?.value as? String else {
            return .failed(error: "Missing event title")
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // Parse start/end times
        if let startString = action.params["start_time"]?.value as? String,
           let startDate = parseDateTime(startString) {
            event.startDate = startDate
            
            if let endString = action.params["end_time"]?.value as? String,
               let endDate = parseDateTime(endString) {
                event.endDate = endDate
            } else {
                // Default to 1 hour duration
                event.endDate = startDate.addingTimeInterval(3600)
            }
        } else {
            return .failed(error: "Missing or invalid start time")
        }
        
        if let notes = action.params["notes"]?.value as? String {
            event.notes = notes
        }
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return .success(message: "已创建日程「\(title)」")
        } catch {
            return .failed(error: "创建日程失败: \(error.localizedDescription)")
        }
    }
    
    private func queryCalendarEvents(_ action: PendingClientAction) async -> NativeToolResult {
        let calendar = Calendar.current
        let now = Date()
        
        // Default: query today's events
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        if events.isEmpty {
            return .success(message: "今天没有日程安排")
        }
        
        let eventList = events.map { event -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let time = formatter.string(from: event.startDate)
            return "• \(time) \(event.title ?? "无标题")"
        }.joined(separator: "\n")
        
        return .success(message: "今天的日程：\n\(eventList)")
    }
    
    // MARK: - Health Data
    
    private func executeHealthAction(_ action: PendingClientAction) async -> NativeToolResult {
        let status = permissionManager.checkStatus(for: .health)
        
        switch status {
        case .notDetermined:
            return .permissionRequired(type: .health)
        case .denied, .restricted:
            return .permissionDenied(fallbackMessage: PermissionType.health.denialMessage)
        case .authorized:
            break
        }
        
        // Health data queries would be implemented here
        // For now, return a placeholder
        return .success(message: "健康数据查询功能开发中")
    }
    
    // MARK: - Screen Time
    
    private func executeScreenTimeAction(_ action: PendingClientAction) async -> NativeToolResult {
        // Screen Time API requires special entitlements
        return .permissionDenied(fallbackMessage: PermissionType.screenTime.denialMessage)
    }
    
    // MARK: - Helpers
    
    private func parseDateTime(_ string: String) -> Date? {
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "HH:mm"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                // If only time was provided, use today's date
                if format == "HH:mm" {
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.hour, .minute], from: date)
                    return calendar.date(bySettingHour: components.hour ?? 0,
                                        minute: components.minute ?? 0,
                                        second: 0,
                                        of: Date())
                }
                return date
            }
        }
        return nil
    }
}
