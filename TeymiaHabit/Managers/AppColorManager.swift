import SwiftUI

@Observable
final class AppColorManager {
    static let shared = AppColorManager()
    
    private let availableColors: [HabitIconColor] = [
        .primary, .gray, .red, .orange, .yellow, .green, .mint, .sky,
        .blue, .cloudBurst, .softLavender, .purple, .pink, .lusciousLime, .celestial, .antarctica,
        .oceanBlue, .bluePink, .sweetMorning, .yellowOrange, .coral, .candy, .brown, .colorPicker,
    ]
    
    func getAvailableColors() -> [HabitIconColor] {
        availableColors
    }
    
    // MARK: - Ring Colors

    func getRingColor(
        for habit: Habit?,
        isCompleted: Bool,
        isExceeded: Bool
    ) -> Color {
        if isCompleted || isExceeded {
            return .green
        } else {
            return habit?.iconColor.color ?? .mainApp
        }
    }
    
    // MARK: - Chart Bar Styles (Simplified)
    
    static func getChartBarStyle(
        isCompleted: Bool,
        isExceeded: Bool,
        habit: Habit
    ) -> AnyShapeStyle {
        if isCompleted || isExceeded {
            return AnyShapeStyle(Color.green.gradient.opacity(0.9))
        } else {
            return AnyShapeStyle(habit.iconColor.color.gradient.opacity(0.9))
        }
    }
    
    static func getInactiveBarStyle() -> AnyShapeStyle {
        AnyShapeStyle(Color.gray.opacity(0.2))
    }
    
    static func getNoProgressBarStyle() -> AnyShapeStyle {
        AnyShapeStyle(Color.gray.opacity(0.3))
    }
}
