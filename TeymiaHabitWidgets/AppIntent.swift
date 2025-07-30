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
        
        do {
            _ = try await OpenURLIntent(url).perform()
        } catch {
            // Expected behavior when switching between apps
        }
        
        return .result()
    }
}

enum AppIntentError: Error {
    case failed
}
