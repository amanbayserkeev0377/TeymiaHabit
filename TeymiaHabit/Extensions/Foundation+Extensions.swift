import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, tableName: nil, bundle: .main, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        String(format: localized, arguments: arguments)
    }
}

extension Notification.Name {
    static let openHabitFromDeeplink = Notification.Name("openHabitFromDeeplink")
    static let dismissAllSheets = Notification.Name("dismissAllSheets")
}
