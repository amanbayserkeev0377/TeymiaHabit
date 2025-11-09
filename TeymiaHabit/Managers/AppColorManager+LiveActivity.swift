import SwiftUI

// MARK: - LiveActivity Color Manager (Simplified)

/// Standalone color manager for LiveActivity extensions
/// Uses native SwiftUI gradients instead of manual dark/light switching
struct LiveActivityColorManager {
    
    // MARK: - Ring Colors
    
    /// Returns single color - SwiftUI's .gradient handles the rest
    static func getRingColor(
        habitColor: HabitIconColor,
        isCompleted: Bool,
        isExceeded: Bool
    ) -> Color {
        if isCompleted || isExceeded {
            return .green
        } else {
            return habitColor.color
        }
    }
    
    // MARK: - Bar Styles
    
    static func getBarStyle(
        habitColor: HabitIconColor,
        isCompleted: Bool,
        isExceeded: Bool
    ) -> AnyShapeStyle {
        if isExceeded {
            return AnyShapeStyle(Color.mint.gradient.opacity(0.9))
        } else if isCompleted {
            return AnyShapeStyle(Color.green.gradient.opacity(0.9))
        } else {
            return AnyShapeStyle(habitColor.color.gradient.opacity(0.9))
        }
    }
}
