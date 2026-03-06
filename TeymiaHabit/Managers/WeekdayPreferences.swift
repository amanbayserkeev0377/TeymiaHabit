import Foundation

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
