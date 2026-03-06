import Foundation

extension Notification.Name {
    static let firstDayOfWeekChanged = Notification.Name("FirstDayOfWeekChanged")
}

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
