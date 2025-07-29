import Foundation

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

// Extension for Date with useful formatting methods
extension Date {
    /// Formats date to a string like "January 1"
    var formattedDayMonth: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d"
        return dateFormatter.string(from: self)
    }
    
    /// Checks if the date is today
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// Checks if the date is yesterday
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
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
    
    // Добавляем форматтер для месяца в именительном падеже
    static let nominativeMonthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"  // LLLL для именительного падежа
        return formatter
    }()
    
    // Метод для даты в формате "число Месяц" с заглавной буквы месяца
    static func dayAndCapitalizedMonth(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        let dateString = formatter.string(from: date)
        
        if let spaceIndex = dateString.firstIndex(of: " "),
           let firstMonthCharIndex = dateString.index(spaceIndex, offsetBy: 1, limitedBy: dateString.endIndex) {
            let prefix = dateString[..<dateString.index(after: spaceIndex)]
            let firstChar = String(dateString[firstMonthCharIndex]).uppercased()
            let suffix = dateString[dateString.index(after: firstMonthCharIndex)...]
            
            return prefix + firstChar + suffix
        }
        
        return dateString
    }
    
    // Метод для "Месяц год" в именительном падеже с заглавной буквы
    static func capitalizedNominativeMonthYear(from date: Date) -> String {
        let dateString = nominativeMonthYear.string(from: date)
        guard let firstChar = dateString.first else { return dateString }
        
        return String(firstChar).uppercased() + dateString.dropFirst()
    }
}

enum ProgressState {
    case inProgress  // < 100%
    case completed   // = 100%
    case exceeded    // > 100%
}
