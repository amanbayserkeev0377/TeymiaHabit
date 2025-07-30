import Foundation

// MARK: - Extensions

extension Int {
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
        
    func formattedAsLocalizedDuration() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(self)) ?? "\(self)s"
    }
}

extension Date {
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
    
    // Uses nominative case for month names (Russian localization)
    static let nominativeMonthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()
    
    static func dayAndCapitalizedMonth(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        let dateString = formatter.string(from: date)
        
        return capitalizeFirstLetterAfterSpace(in: dateString)
    }
    
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

private extension String {
    func capitalizingFirstLetter() -> String {
        guard let firstChar = self.first else { return self }
        return String(firstChar).uppercased() + self.dropFirst()
    }
}

enum ProgressState {
    case inProgress
    case completed
    case exceeded
}
