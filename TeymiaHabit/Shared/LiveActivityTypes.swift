import ActivityKit
import Foundation

// MARK: - Live Activity Attributes
struct HabitActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentProgress: Int
        var isTimerRunning: Bool
        var timerStartTime: Date?
        var lastUpdateTime: Date
    }
    
    let habitId: String
    let habitName: String
    let habitGoal: Int
    let habitType: HabitActivityType
    let habitIcon: String
    let habitIconColor: HabitIconColor // NEW: Use enum instead of String
}

// MARK: - Shared Habit Type for Live Activities
enum HabitActivityType: String, Codable {
    case count = "count"
    case time = "time"
}

// MARK: - Widget Action Types
enum WidgetAction: String {
    case toggleTimer = "toggleTimer"
    case dismissActivity = "dismissActivity"
}

struct WidgetActionNotification {
    let action: WidgetAction
    let habitId: String
    let timestamp: Date
    let actionId: String // ✅ НОВОЕ: Уникальный ID действия
}

// MARK: - Helper Extensions
extension HabitActivityAttributes.ContentState {
    var elapsedSeconds: Int {
        guard let startTime = timerStartTime else { return 0 }
        return Int(Date().timeIntervalSince(startTime))
    }
    
    var totalTimeSeconds: Int {
        return currentProgress + (isTimerRunning ? elapsedSeconds : 0)
    }
    
    var formattedTime: String {
        return totalTimeSeconds.formattedAsTime()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let widgetActionReceived = Notification.Name("WidgetActionReceived")
    static let widgetActionProcessed = Notification.Name("WidgetActionProcessed") // ✅ НОВОЕ
}
