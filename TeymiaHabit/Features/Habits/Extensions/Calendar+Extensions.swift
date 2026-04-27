import Foundation

extension Calendar {
    static var userPreferred: Calendar {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar
    }
}
