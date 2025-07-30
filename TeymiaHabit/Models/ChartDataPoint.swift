import Foundation

/// Represents a single data point for habit progress charts
/// Used in statistics views to display habit completion over time
struct ChartDataPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Int // Progress value (seconds for time habits, count for count habits)
    let goal: Int // Target goal for the habit
    let habit: Habit
    
    // MARK: - Equatable
    
    static func == (lhs: ChartDataPoint, rhs: ChartDataPoint) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Progress Calculation
    
    var completionPercentage: Double {
        guard goal > 0 else { return 0 }
        return Double(value) / Double(goal)
    }
    
    var isCompleted: Bool {
        value >= goal
    }
    
    var isOverAchieved: Bool {
        value > goal
    }
    
    // MARK: - Formatting
    
    var formattedValue: String {
        switch habit.type {
        case .count:
            return "\(value)"
        case .time:
            return value.formattedAsTime()
        }
    }
    
    var formattedGoal: String {
        switch habit.type {
        case .count:
            return "\(goal)"
        case .time:
            return goal.formattedAsTime()
        }
    }
    
    /// Returns formatted time without seconds for cleaner chart display
    var formattedValueWithoutSeconds: String {
        switch habit.type {
        case .count:
            return "\(value)"
        case .time:
            let hours = value / 3600
            let minutes = (value % 3600) / 60
            
            if hours > 0 {
                return String(format: "%d:%02d", hours, minutes)
            } else if minutes > 0 {
                return String(format: "0:%02d", minutes)
            } else {
                return "0"
            }
        }
    }
}
