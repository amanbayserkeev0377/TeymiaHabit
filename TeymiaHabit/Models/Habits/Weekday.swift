import Foundation

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
