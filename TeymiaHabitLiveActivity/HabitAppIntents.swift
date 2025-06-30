import AppIntents
import Foundation

struct StopTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Toggle Timer"
    
    @Parameter(title: "Habit ID")
    var habitId: String
    
    init() {}
    init(habitId: String) { self.habitId = habitId }
    
    func perform() async throws -> some IntentResult {
        // Use development or production App Groups based on bundle ID
        let appGroupsID: String
        if Bundle.main.bundleIdentifier?.contains(".dev") == true {
            appGroupsID = "group.com.amanbayserkeev.teymiahabit.dev"
        } else {
            appGroupsID = "group.com.amanbayserkeev.teymiahabit"
        }
        
        let userDefaults = UserDefaults(suiteName: appGroupsID)
        
        let update = [
            "action": "toggleTimer",
            "habitId": habitId,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        userDefaults?.set(update, forKey: "live_activity_action")
        
        return .result()
    }
}

struct CompleteHabitIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Complete Habit"
    
    @Parameter(title: "Habit ID")
    var habitId: String
    
    init() {}
    init(habitId: String) { self.habitId = habitId }
    
    func perform() async throws -> some IntentResult {
        let appGroupsID: String
        if Bundle.main.bundleIdentifier?.contains(".dev") == true {
            appGroupsID = "group.com.amanbayserkeev.teymiahabit.dev"
        } else {
            appGroupsID = "group.com.amanbayserkeev.teymiahabit"
        }
        
        let userDefaults = UserDefaults(suiteName: appGroupsID)
        
        let update = [
            "action": "complete",
            "habitId": habitId,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        userDefaults?.set(update, forKey: "live_activity_action")
        
        return .result()
    }
}

struct AddTimeIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Add Time"
    
    @Parameter(title: "Habit ID")
    var habitId: String
    
    init() {}
    init(habitId: String) { self.habitId = habitId }
    
    func perform() async throws -> some IntentResult {
        let appGroupsID: String
        if Bundle.main.bundleIdentifier?.contains(".dev") == true {
            appGroupsID = "group.com.amanbayserkeev.teymiahabit.dev"
        } else {
            appGroupsID = "group.com.amanbayserkeev.teymiahabit"
        }
        
        let userDefaults = UserDefaults(suiteName: appGroupsID)
        
        let update = [
            "action": "addTime",
            "habitId": habitId,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        userDefaults?.set(update, forKey: "live_activity_action")
        
        return .result()
    }
}
