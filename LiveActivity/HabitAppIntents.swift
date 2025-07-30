import AppIntents
import Foundation

struct OpenHabitIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Open Habit"
    
    @Parameter(title: "Habit ID")
    var habitId: String
    
    init() {}
    init(habitId: String) { self.habitId = habitId }
    
    func perform() async throws -> some IntentResult {
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
