import Foundation

// MARK: - Int Extensions for Time Formatting

extension Int {
    /// Formats seconds to a string like "1:30:45" (hours:minutes:seconds) or "23:45" (minutes:seconds)
    /// Used for displaying progress of time habits
    func formattedAsTime() -> String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
        
    /// Formats seconds as localized duration (e.g., "1h 30m", "45m", "1h")
    /// Used for displaying goals with proper localization
    func formattedAsLocalizedDuration() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(self)) ?? "\(self)s"
    }
}

// MARK: - Date Extensions

extension Date {
    /// Formats date to a string like "January 1"
    var formattedDayMonth: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d"
        return dateFormatter.string(from: self)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
}

// MARK: - DateFormatter Extensions

extension DateFormatter {
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    static let dayOfMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    static let shortMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()
    
    static let weekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
    
    /// Uses nominative case for month names (Russian localization specific)
    static let nominativeMonthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"  // LLLL for nominative case
        return formatter
    }()
    
    /// Formats date as "day Month" with capitalized month name
    static func dayAndCapitalizedMonth(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        let dateString = formatter.string(from: date)
        
        return capitalizeFirstLetterAfterSpace(in: dateString)
    }
    
    /// Formats date as "Month year" in nominative case with capitalized month
    static func capitalizedNominativeMonthYear(from date: Date) -> String {
        let dateString = nominativeMonthYear.string(from: date)
        return dateString.capitalizingFirstLetter()
    }
    
    // MARK: - Private Helpers
    
    private static func capitalizeFirstLetterAfterSpace(in string: String) -> String {
        guard let spaceIndex = string.firstIndex(of: " "),
              let firstMonthCharIndex = string.index(spaceIndex, offsetBy: 1, limitedBy: string.endIndex) else {
            return string
        }
        
        let prefix = string[..<string.index(after: spaceIndex)]
        let firstChar = String(string[firstMonthCharIndex]).uppercased()
        let suffix = string[string.index(after: firstMonthCharIndex)...]
        
        return prefix + firstChar + suffix
    }
}

// MARK: - String Extensions

private extension String {
    func capitalizingFirstLetter() -> String {
        guard let firstChar = self.first else { return self }
        return String(firstChar).uppercased() + self.dropFirst()
    }
}

// MARK: - Progress State Enum

enum ProgressState {
    case inProgress  // < 100%
    case completed   // = 100%
    case exceeded    // > 100%
}
