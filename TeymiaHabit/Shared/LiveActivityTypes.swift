import SwiftUI
import ActivityKit
import WidgetKit

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
    let habitIconColor: HabitIconColor
    let habitHexColor: String?
    
    var actualColor: Color {
        if let hex = habitHexColor {
            return Color(hex: hex)
        }
        return habitIconColor.baseColor
    }
}

// MARK: - Shared Types (все платформы)
enum HabitActivityType: String, Codable, CaseIterable {
    case count
    case time

    var localizedName: LocalizedStringResource {
        LocalizedStringResource(String.LocalizationValue(self.rawValue))
    }
}

enum WidgetAction: String, CaseIterable {
    case toggleTimer
    case dismissActivity
    
    var localizedName: LocalizedStringResource {
        LocalizedStringResource(String.LocalizationValue(self.rawValue))
    }
}

struct WidgetActionNotification {
    let action: WidgetAction
    let habitId: String
    let timestamp: Date
    let actionId: String
    
    init(action: WidgetAction, habitId: String) {
        self.action = action
        self.habitId = habitId
        self.timestamp = Date()
        self.actionId = UUID().uuidString
    }
}

// MARK: - Extensions
extension HabitActivityAttributes.ContentState {
    var elapsedSeconds: Int {
        guard let startTime = timerStartTime else { return 0 }
        return Int(Date().timeIntervalSince(startTime))
    }
    
    var totalTimeSeconds: Int {
        currentProgress + (isTimerRunning ? elapsedSeconds : 0)
    }
}

extension Notification.Name {
    static let widgetActionReceived = Notification.Name("WidgetActionReceived")
    static let widgetActionProcessed = Notification.Name("WidgetActionProcessed")
    static let liveActivityStateChanged = Notification.Name("LiveActivityStateChanged")
}

// MARK: - Live Activity Icon View
struct LiveActivityHabitIcon: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    let size: CGFloat
    
    var body: some View {
        HabitIconView(
            iconName: context.attributes.habitIcon,
            color: context.attributes.actualColor,
            size: size
        )
    }
}
