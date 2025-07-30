import Foundation

// MARK: - Weekday Preferences Manager

@Observable
class WeekdayPreferences {
    static let shared = WeekdayPreferences()
    
    /// User's preferred first day of week (1 = Sunday, 2 = Monday, etc.)
    private(set) var firstDayOfWeek: Int
    
    private init() {
        // Load saved preference or default to system setting
        self.firstDayOfWeek = UserDefaults.standard.integer(forKey: "firstDayOfWeek")
    }
    
    func updateFirstDayOfWeek(_ value: Int) {
        self.firstDayOfWeek = value
        UserDefaults.standard.set(value, forKey: "firstDayOfWeek")
    }
}

// MARK: - Weekday Enum

/// Raw values match Foundation Calendar weekday numbering (1 = Sunday, 2 = Monday, etc.)
enum Weekday: Int, CaseIterable, Hashable, Sendable {
    case sunday = 1, monday = 2, tuesday = 3, wednesday = 4, thursday = 5, friday = 6, saturday = 7
    
    // MARK: - Factory Methods
    
    static func from(date: Date) -> Weekday {
        let calendar = Calendar.current
        let weekdayNumber = calendar.component(.weekday, from: date)
        return Weekday(rawValue: weekdayNumber) ?? .sunday
    }
    
    static var orderedByUserPreference: [Weekday] {
        Calendar.userPreferred.weekdays
    }
    
    // MARK: - Display Properties
    
    var shortName: String {
        Calendar.current.shortWeekdaySymbols[self.rawValue - 1]
    }
    
    var fullName: String {
        Calendar.current.weekdaySymbols[self.rawValue - 1]
    }
    
    var arrayIndex: Int {
        self.rawValue - 1
    }
    
    var isWeekend: Bool {
        self == .saturday || self == .sunday
    }
    
    // MARK: - Navigation
    
    var next: Weekday {
        Weekday(rawValue: (self.rawValue % 7) + 1) ?? .sunday
    }
    
    var previous: Weekday {
        Weekday(rawValue: self.rawValue == 1 ? 7 : self.rawValue - 1) ?? .sunday
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let firstDayOfWeekChanged = Notification.Name("FirstDayOfWeekChanged")
}

// MARK: - Calendar Extensions

extension Calendar {
    /// Creates calendar with user's preferred first day of week
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
    
    var orderedShortWeekdaySymbols: [String] {
        let allSymbols = self.shortWeekdaySymbols
        return (0..<7).map {
            allSymbols[(($0 + self.firstWeekday - 1) % 7)]
        }
    }
    
    var orderedFormattedFullWeekdaySymbols: [String] {
        orderedWeekdaySymbols.map { $0.capitalized }
    }
    
    var orderedWeekdayInitials: [String] {
        orderedShortWeekdaySymbols.map {
            String($0.prefix(1)).uppercased()
        }
    }
    
    var orderedWeekdaySymbols: [String] {
        let allSymbols = self.weekdaySymbols
        return (0..<7).map {
            allSymbols[(($0 + self.firstWeekday - 1) % 7)]
        }
    }
    
    var orderedFormattedWeekdaySymbols: [String] {
        orderedShortWeekdaySymbols.map { $0.capitalized }
    }
    
    // MARK: - Utility Methods
    
    func systemWeekdayFromOrdered(index: Int) -> Int {
        (index + self.firstWeekday - 1) % 7 + 1
    }
}
