import Foundation

/// Centralized history limits for habit tracking across the app
enum HistoryLimits {
    /// Maximum habit history in years (used in charts, calendars, and date pickers)
    static let maxYears = 5
    
    /// Returns the earliest date that can be displayed in the app
    static func earliestAllowedDate() -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .year, value: -maxYears, to: Date()) ?? Date()
    }
    
    /// Applies history limit to habit start date for display purposes
    /// - Parameter startDate: Original habit start date
    /// - Returns: Date clamped to history limit (not earlier than maxYears ago)
    static func limitStartDate(_ startDate: Date) -> Date {
        max(startDate, earliestAllowedDate())
    }
    
    /// Date range for DatePicker when creating/editing habits
    static var datePickerRange: ClosedRange<Date> {
        earliestAllowedDate()...Date()
    }
}
