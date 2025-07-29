import Foundation
import SwiftData

/// Represents a single completion entry for a habit on a specific date
/// Stores the progress value (count or time in seconds) achieved for that day
@Model
final class HabitCompletion {
    /// Date when the progress was made (stored as start of day)
    var date: Date = Date()
    
    /// Progress value: count for count-based habits, seconds for time-based habits
    var value: Int = 0
    
    /// Reference to the parent habit (inverse relationship)
    var habit: Habit?
    
    // MARK: - Initializers
    
    init(date: Date = Date(), value: Int = 0, habit: Habit? = nil) {
        self.date = date
        self.value = value
        self.habit = habit
    }
    
    // MARK: - Time-based Habit Helpers
    
    /// Formatted time string for time-based habits (HH:MM:SS)
    var formattedTime: String {
        return value.formattedAsTime()
    }
    
    /// Add minutes to current time value (for time-based habits)
    func addMinutes(_ minutes: Int) {
        value += minutes * 60
    }
    
    // MARK: - Time Components (for time-based habits)
    
    /// Hours component of the time value
    var hours: Int {
        value / 3600
    }
    
    /// Minutes component of the time value
    var minutes: Int {
        (value % 3600) / 60
    }
    
    /// Seconds component of the time value
    var seconds: Int {
        value % 60
    }
    
    // MARK: - Utility Methods
    
    /// Converts time components to total seconds
    /// - Parameters:
    ///   - hours: Number of hours
    ///   - minutes: Number of minutes
    ///   - seconds: Number of seconds (default: 0)
    /// - Returns: Total time in seconds
    static func secondsFrom(hours: Int, minutes: Int, seconds: Int = 0) -> Int {
        return (hours * 3600) + (minutes * 60) + seconds
    }
}
