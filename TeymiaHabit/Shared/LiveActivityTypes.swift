import ActivityKit
import Foundation
import SwiftUI
import WidgetKit

// MARK: - Live Activity Attributes (без изменений - поля уже есть)
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
    let habitIcon: String // ✅ Уже есть
    let habitIconColor: HabitIconColor // ✅ Уже есть
}

// MARK: - Shared Habit Type for Live Activities
enum HabitActivityType: String, Codable, CaseIterable {
    case count = "count"
    case time = "time"
    
    var displayName: String {
        switch self {
        case .count:
            return "Count"
        case .time:
            return "Time"
        }
    }
}

// MARK: - Widget Action Types
enum WidgetAction: String, CaseIterable {
    case toggleTimer = "toggleTimer"
    case dismissActivity = "dismissActivity"
    
    var displayName: String {
        switch self {
        case .toggleTimer:
            return "Toggle Timer"
        case .dismissActivity:
            return "Dismiss Activity"
        }
    }
}

struct WidgetActionNotification {
    let action: WidgetAction
    let habitId: String
    let timestamp: Date
    let actionId: String // Уникальный ID действия для предотвращения дубликатов
    
    init(action: WidgetAction, habitId: String) {
        self.action = action
        self.habitId = habitId
        self.timestamp = Date()
        self.actionId = UUID().uuidString
    }
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
    
    var progressPercentage: Double {
        // Для расчета процента нужен goal из attributes
        return 0.0
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let widgetActionReceived = Notification.Name("WidgetActionReceived")
    static let widgetActionProcessed = Notification.Name("WidgetActionProcessed")
    static let liveActivityStateChanged = Notification.Name("LiveActivityStateChanged")
}

// MARK: - ✅ Extension для Live Activity Widget (используя существующий universalIcon)
struct LiveActivityHabitIcon: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    let size: CGFloat
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        EmptyView()
            .universalIcon(
                iconId: context.attributes.habitIcon,
                baseSize: size,
                color: context.attributes.habitIconColor,
                colorScheme: colorScheme // ✅ Автоматически получаем из Environment
            )
    }
}
