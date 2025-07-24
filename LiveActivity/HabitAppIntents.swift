import AppIntents
import Foundation

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
