import Foundation

// MARK: - Weekday Preferences Manager

/// Observable manager for user's first day of week preference
/// Handles persistence and notification of changes
@Observable
class WeekdayPreferences {
    static let shared = WeekdayPreferences()
    
    /// User's preferred first day of week (1 = Sunday, 2 = Monday, etc.)
    /// Automatically persisted to UserDefaults
    private(set) var firstDayOfWeek: Int
    
    private init() {
        // Load saved preference or default to system setting
        self.firstDayOfWeek = UserDefaults.standard.integer(forKey: "firstDayOfWeek")
    }
    
    /// Updates the first day of week preference
    /// - Parameter value: New first day value (1-7, where 1 = Sunday)
    func updateFirstDayOfWeek(_ value: Int) {
        self.firstDayOfWeek = value
        UserDefaults.standard.set(value, forKey: "firstDayOfWeek")
    }
}

// MARK: - Weekday Enum

/// Represents days of the week with utility methods
/// Raw values match Foundation Calendar weekday numbering (1 = Sunday, 2 = Monday, etc.)
enum Weekday: Int, CaseIterable, Hashable, Sendable {
    case sunday = 1, monday = 2, tuesday = 3, wednesday = 4, thursday = 5, friday = 6, saturday = 7
    
    // MARK: - Factory Methods
    
    /// Creates a Weekday from a Date
    /// - Parameter date: Date to extract weekday from
    /// - Returns: Corresponding Weekday enum case
    static func from(date: Date) -> Weekday {
        let calendar = Calendar.current
        let weekdayNumber = calendar.component(.weekday, from: date)
        return Weekday(rawValue: weekdayNumber) ?? .sunday
    }
    
    /// Returns weekdays ordered by user's preference (Monday first vs Sunday first)
    static var orderedByUserPreference: [Weekday] {
        Calendar.userPreferred.weekdays
    }
    
    // MARK: - Display Properties
    
    /// Short localized name (Mon, Tue, etc.)
    var shortName: String {
        Calendar.current.shortWeekdaySymbols[self.rawValue - 1]
    }
    
    /// Full localized name (Monday, Tuesday, etc.)
    var fullName: String {
        Calendar.current.weekdaySymbols[self.rawValue - 1]
    }
    
    /// Array index for this weekday (0-6)
    var arrayIndex: Int {
        self.rawValue - 1
    }
    
    /// Whether this day is typically a weekend
    var isWeekend: Bool {
        self == .saturday || self == .sunday
    }
    
    // MARK: - Navigation
    
    /// Next day of the week (wraps around Sunday -> Monday)
    var next: Weekday {
        Weekday(rawValue: (self.rawValue % 7) + 1) ?? .sunday
    }
    
    /// Previous day of the week (wraps around Monday -> Sunday)
    var previous: Weekday {
        Weekday(rawValue: self.rawValue == 1 ? 7 : self.rawValue - 1) ?? .sunday
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when user changes their first day of week preference
    static let firstDayOfWeekChanged = Notification.Name("FirstDayOfWeekChanged")
}

// MARK: - Calendar Extensions

extension Calendar {
    /// Creates calendar with user's preferred first day of week
    /// Uses current timezone and user's weekday preference
    static var userPreferred: Calendar {
        let firstDayOfWeek = WeekdayPreferences.shared.firstDayOfWeek
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        // Use user preference if set, otherwise keep system default
        if firstDayOfWeek != 0 {
            calendar.firstWeekday = firstDayOfWeek
        }
        
        return calendar
    }
    
    /// Returns weekdays ordered according to this calendar's first day setting
    /// Example: If Monday is first day, returns [Monday, Tuesday, ..., Sunday]
    var weekdays: [Weekday] {
        let weekdayValueOfFirst = self.firstWeekday
        let allWeekdays = Weekday.allCases
        
        // Find starting index based on first weekday preference
        guard let firstWeekdayIndex = allWeekdays.firstIndex(where: { $0.rawValue == weekdayValueOfFirst }) else {
            return Array(allWeekdays)
        }
        
        // Reorder array starting from preferred first day
        var result = [Weekday]()
        for i in 0..<allWeekdays.count {
            let index = (firstWeekdayIndex + i) % allWeekdays.count
            result.append(allWeekdays[index])
        }
        
        return result
    }
    
    // MARK: - Localized Symbol Arrays
    
    /// Short weekday symbols ordered by this calendar's first day
    /// Example: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"] for Monday-first
    var orderedShortWeekdaySymbols: [String] {
        let allSymbols = self.shortWeekdaySymbols
        return (0..<7).map {
            allSymbols[(($0 + self.firstWeekday - 1) % 7)]
        }
    }
    
    /// Full weekday symbols ordered by this calendar's first day, capitalized
    /// Example: ["Monday", "Tuesday", ...] for Monday-first
    var orderedFormattedFullWeekdaySymbols: [String] {
        orderedWeekdaySymbols.map { $0.capitalized }
    }
    
    /// Single-letter weekday initials ordered by this calendar's first day
    /// Example: ["M", "T", "W", "T", "F", "S", "S"] for Monday-first
    var orderedWeekdayInitials: [String] {
        orderedShortWeekdaySymbols.map {
            String($0.prefix(1)).uppercased()
        }
    }
    
    /// Full weekday symbols ordered by this calendar's first day
    var orderedWeekdaySymbols: [String] {
        let allSymbols = self.weekdaySymbols
        return (0..<7).map {
            allSymbols[(($0 + self.firstWeekday - 1) % 7)]
        }
    }
    
    /// Short weekday symbols ordered by this calendar's first day, capitalized
    var orderedFormattedWeekdaySymbols: [String] {
        orderedShortWeekdaySymbols.map { $0.capitalized }
    }
    
    // MARK: - Utility Methods
    
    /// Converts ordered array index to system weekday number
    /// - Parameter index: Index in ordered weekday array (0-6)
    /// - Returns: System weekday number (1-7)
    func systemWeekdayFromOrdered(index: Int) -> Int {
        (index + self.firstWeekday - 1) % 7 + 1
    }
}
