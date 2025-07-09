import AppIntents
import Foundation

struct StopTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Toggle Timer"
    
    @Parameter(title: "Habit ID")
    var habitId: String
    
    init() {}
    init(habitId: String) { self.habitId = habitId }
    
    func perform() async throws -> some IntentResult {
        let userDefaults = UserDefaults(suiteName: "group.com.amanbayserkeev.teymiahabit")
        
        let update = [
            "action": "toggleTimer",
            "habitId": habitId,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        // ✅ ИСПРАВЛЕНО: Уникальный ключ для каждой привычки (как в HabitLiveActivityManager)
        let uniqueKey = "live_activity_action_\(habitId)"
        userDefaults?.set(update, forKey: uniqueKey)
        
        print("🔧 Widget action stored with key: \(uniqueKey)")
        return .result()
    }
}

struct OpenHabitIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Open Habit"
    
    @Parameter(title: "Habit ID")
    var habitId: String
    
    init() {}
    init(habitId: String) { self.habitId = habitId }
    
    func perform() async throws -> some IntentResult {
        // ИСПРАВЛЕНО: Widget extensions не имеют доступа к UIApplication
        // Вместо этого используем URL схему через App Intents
        
        // Записываем deep link action в UserDefaults для основного приложения
        let userDefaults = UserDefaults(suiteName: "group.com.amanbayserkeev.teymiahabit")
        
        let deepLinkAction = [
            "action": "openHabit",
            "habitId": habitId,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        userDefaults?.set(deepLinkAction, forKey: "deep_link_action")
        
        return .result()
    }
}

// NEW: Intent for dismissing the Live Activity
struct DismissActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Dismiss Activity"
    
    @Parameter(title: "Habit ID")
    var habitId: String
    
    init() {}
    init(habitId: String) { self.habitId = habitId }
    
    func perform() async throws -> some IntentResult {
        let userDefaults = UserDefaults(suiteName: "group.com.amanbayserkeev.teymiahabit")
        
        let update = [
            "action": "dismissActivity",
            "habitId": habitId,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        // ✅ ИСПРАВЛЕНО: Уникальный ключ для каждой привычки (как в HabitLiveActivityManager)
        let uniqueKey = "live_activity_action_\(habitId)"
        userDefaults?.set(update, forKey: uniqueKey)
        
        print("🔧 Widget action stored with key: \(uniqueKey)")
        return .result()
    }
}
