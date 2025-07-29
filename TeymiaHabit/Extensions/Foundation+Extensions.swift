import Foundation

// MARK: - String Extensions

extension String {
    /// Returns the localized version of the string
    /// Uses the main bundle's Localizable.strings file
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: .main, comment: "")
    }
    
    /// Returns the localized string with formatted arguments
    /// - Parameter arguments: Arguments to substitute in the localized string
    /// - Returns: Formatted localized string
    func localized(with arguments: CVarArg...) -> String {
        return String(format: localized, arguments: arguments)
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    /// Posted when app should open a specific habit from deep link
    static let openHabitFromDeeplink = Notification.Name("openHabitFromDeeplink")
    
    /// Posted when all presented sheets should be dismissed
    static let dismissAllSheets = Notification.Name("dismissAllSheets")
}
