import Foundation

/// Defines the two types of habits supported by the app
enum HabitType: Int, Codable, CaseIterable {
    /// Count-based habits (e.g., "drink 8 glasses of water")
    case count
    
    /// Time-based habits (e.g., "read for 30 minutes")
    case time
    
    /// Localized display name for the habit type
    var name: String {
        switch self {
        case .count:
            return "count".localized
        case .time:
            return "time".localized
        }
    }
    
    /// Default goal value when creating a new habit of this type
    var defaultGoal: Int {
        switch self {
        case .count:
            return 1 // Default: complete once
        case .time:
            return 1800 // Default: 30 minutes (30 * 60 seconds)
        }
    }
}
