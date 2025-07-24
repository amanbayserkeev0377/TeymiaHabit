import AppIntents
import Foundation

struct OpenHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Habit"
    static var description = IntentDescription("Opens a specific habit in Teymia Habit app")
    
    @Parameter(title: "Habit ID")
    var habitId: String
    
    init() {}
    
    init(habitId: String) {
        self.habitId = habitId
    }
    
    func perform() async throws -> some IntentResult {
        let urlString = "teymiahabit://habit/\(habitId)"
        guard let url = URL(string: urlString) else {
            throw AppIntentError.failed
        }
        
        // Open main app with deep link
        do {
            _ = try await OpenURLIntent(url).perform()
        } catch {
            // Ignore error - this is expected when switching apps
            print("OpenURL completed (may not return): \(error)")
        }
        
        return .result()
    }
}

enum AppIntentError: Error {
    case failed
}
