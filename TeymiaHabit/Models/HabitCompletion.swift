import Foundation
import SwiftData

/// Represents a single completion entry for a habit on a specific date
/// Stores the progress value (count or time in seconds) achieved for that day
@Model
final class HabitCompletion {
    var date: Date = Date()
    var value: Int = 0
    var habit: Habit?
    
    // MARK: - Initializers
    
    init(date: Date = Date(), value: Int = 0, habit: Habit? = nil) {
        self.date = date
        self.value = value
        self.habit = habit
    }
    
    // MARK: - Time-based Habit Helpers
    
    var formattedTime: String {
        value.formattedAsTime()
    }
    
    func addMinutes(_ minutes: Int) {
        value += minutes * 60
    }
    
    // MARK: - Time Components
    
    var hours: Int {
        value / 3600
    }
    
    var minutes: Int {
        (value % 3600) / 60
    }
    
    var seconds: Int {
        value % 60
    }
    
    // MARK: - Utility Methods
    
    static func secondsFrom(hours: Int, minutes: Int, seconds: Int = 0) -> Int {
        (hours * 3600) + (minutes * 60) + seconds
    }
}
