import SwiftUI

final class AppColorManager: ObservableObject {
    static let shared = AppColorManager()
    
    // MARK: - Published Properties
    @Published private(set) var selectedColor: HabitIconColor
    @AppStorage("selectedAppColor") private var selectedColorId: String?
    
    private let availableColors: [HabitIconColor] = [
        .cloudBurst, .primary, .red, .orange, .yellow, .green, .mint, .sky, .blue,
        .gray, .softLavender, .purple, .pink, .lusciousLime, .celestial,
        .antarctica, .oceanBlue, .bluePink, .sweetMorning, .yellowOrange, .coral, .candy, .brown, .colorPicker,
    ]
    
    // MARK: - Initialization
    private init() {
        selectedColor = .primary
        loadSavedColor()
    }
    
    // MARK: - Public Interface
    func setAppColor(_ color: HabitIconColor) {
        selectedColor = color
        selectedColorId = color.rawValue
    }
    
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
            return habit?.iconColor.color ?? selectedColor.color
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

// MARK: - Private Helpers
private extension AppColorManager {
    func loadSavedColor() {
        guard let savedColorId = selectedColorId,
              let savedColor = HabitIconColor(rawValue: savedColorId) else {
            return
        }
        selectedColor = savedColor
    }
}

// MARK: - Static Ring Colors (Widget/LiveActivity Support)
extension AppColorManager {
    
    /// Static method for getting ring color - NO dependency on Habit model
    static func getRingColor(
        habitColor: HabitIconColor,
        isCompleted: Bool,
        isExceeded: Bool
    ) -> Color {
        if isExceeded {
            return .mint
        } else if isCompleted {
            return .green
        } else {
            return habitColor.color
        }
    }
}
