import AppIntents
import Foundation

struct OpenHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Habit"
    static var description = IntentDescription("Opens a specific habit in Teymia Habit app")
    static var openAppWhenRun: Bool = true // System will open the app
    
    @Parameter(title: "Habit ID")
    var habitId: String
    
    init() {}
    
    init(habitId: String) {
        self.habitId = habitId
    }
    
    func perform() async throws -> some IntentResult {
        // Store the habit ID that the main app will read when it opens
        if let sharedDefaults = UserDefaults(suiteName: "group.com.amanbayserkeev.teymiahabit") {
            sharedDefaults.set(habitId, forKey: "pendingHabitIdFromWidget")
            sharedDefaults.synchronize()
        }
        
        return .result()
    }
}

enum AppIntentError: Error {
    case failed
}
