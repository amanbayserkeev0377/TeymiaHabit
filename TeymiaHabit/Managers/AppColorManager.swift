import SwiftUI

final class AppColorManager: ObservableObject {
    static let shared = AppColorManager()
    
    // MARK: - Published Properties
    @Published private(set) var selectedColor: HabitIconColor
    @AppStorage("selectedAppColor") private var selectedColorId: String?
    
    // MARK: - Constants
    struct ColorConstants {
        static let completedLightGreen = Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.3, alpha: 1))
        static let completedDarkGreen = Color(#colorLiteral(red: 0.2, green: 0.55, blue: 0.05, alpha: 1))
        static let exceededLightMint = Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.9, alpha: 1))
        static let exceededDarkGreen = Color(#colorLiteral(red: 0.2, green: 0.55, blue: 0.05, alpha: 1))
    }
    
    private let availableColors: [HabitIconColor] = [
        .primary, .celestial, .brown, .red, .orange, .yellow, .mint, .green,
        .blue, .sky, .gray, .softLavender, .purple, .pink, .cloudBurst, .lusciousLime,
        .antarctica, .oceanBlue, .bluePink, .sweetMorning, .yellowOrange, .coral, .candy, .colorPicker,
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
    
    /// Get ring colors for progress rings
    /// Returns gradient array accounting for -90° rotation in ProgressRingCircle
    func getRingColors(
        for habit: Habit?,
        isCompleted: Bool,
        isExceeded: Bool,
        colorScheme: ColorScheme
    ) -> [Color] {
        let visualColors = getVisualRingColors(
            for: habit,
            isCompleted: isCompleted,
            isExceeded: isExceeded,
            colorScheme: colorScheme
        )
        
        // Convert visual order to gradient array order for rotated ring
        // Due to -90° rotation: gradient[0] = visual bottom, gradient[1] = visual top
        return [visualColors.bottom, visualColors.top]
    }
    
    /// Get colors in intuitive visual order (what user actually sees)
    private func getVisualRingColors(
        for habit: Habit?,
        isCompleted: Bool,
        isExceeded: Bool,
        colorScheme: ColorScheme
    ) -> (top: Color, bottom: Color) {
        let habitState = HabitState(isCompleted: isCompleted, isExceeded: isExceeded)
        
        switch habitState {
        case .completed:
            let visualTop = colorScheme == .dark ? ColorConstants.completedDarkGreen : ColorConstants.completedLightGreen
            let visualBottom = colorScheme == .dark ? ColorConstants.completedLightGreen : ColorConstants.completedDarkGreen
            return (top: visualTop, bottom: visualBottom)
            
        case .exceeded:
            let visualTop = colorScheme == .dark ? ColorConstants.exceededDarkGreen : ColorConstants.exceededLightMint
            let visualBottom = colorScheme == .dark ? ColorConstants.exceededLightMint : ColorConstants.exceededDarkGreen
            return (top: visualTop, bottom: visualBottom)
            
        case .inProgress:
            let habitColor = habit?.iconColor ?? selectedColor
            let visualTop = colorScheme == .dark ? habitColor.darkColor : habitColor.lightColor
            let visualBottom = colorScheme == .dark ? habitColor.lightColor : habitColor.darkColor
            return (top: visualTop, bottom: visualBottom)
        }
    }
    
    // MARK: - Chart Colors for Bars
    
    static func getChartBarStyle(
        isCompleted: Bool,
        isExceeded: Bool,
        habit: Habit,
        colorScheme: ColorScheme
    ) -> AnyShapeStyle {
        if isExceeded {
            return getExceededBarStyle(for: colorScheme)
        } else if isCompleted {
            return getCompletedBarStyle(for: colorScheme)
        } else {
            return getPartialProgressBarStyle(for: habit, colorScheme: colorScheme)
        }
    }
    
    static func getCompletedBarStyle(for colorScheme: ColorScheme) -> AnyShapeStyle {
        let topColor = colorScheme == .dark ? ColorConstants.completedDarkGreen : ColorConstants.completedLightGreen
        let bottomColor = colorScheme == .dark ? ColorConstants.completedLightGreen : ColorConstants.completedDarkGreen
        
        return AnyShapeStyle(
            LinearGradient(
                colors: [topColor, bottomColor],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    static func getExceededBarStyle(for colorScheme: ColorScheme) -> AnyShapeStyle {
        let topColor = colorScheme == .dark ? ColorConstants.exceededDarkGreen : ColorConstants.exceededLightMint
        let bottomColor = colorScheme == .dark ? ColorConstants.exceededLightMint : ColorConstants.exceededDarkGreen
        
        return AnyShapeStyle(
            LinearGradient(
                colors: [topColor, bottomColor],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    static func getPartialProgressBarStyle(for habit: Habit, colorScheme: ColorScheme) -> AnyShapeStyle {
        AnyShapeStyle(habit.iconColor.adaptiveGradient(for: colorScheme).opacity(0.9))
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

// MARK: - Supporting Types
extension AppColorManager {
    enum HabitState {
        case inProgress, completed, exceeded
        
        init(isCompleted: Bool, isExceeded: Bool) {
            if isExceeded {
                self = .exceeded
            } else if isCompleted {
                self = .completed
            } else {
                self = .inProgress
            }
        }
    }
}

// MARK: - Static Ring Colors (Widget Support)
extension AppColorManager {
    
    /// Static method for getting ring colors - NO dependency on Habit model
    static func getRingColors(
        habitColor: HabitIconColor,
        isCompleted: Bool,
        isExceeded: Bool,
        colorScheme: ColorScheme
    ) -> [Color] {
        let visualColors = getVisualRingColors(
            habitColor: habitColor,
            isCompleted: isCompleted,
            isExceeded: isExceeded,
            colorScheme: colorScheme
        )
        
        // Convert visual order to gradient array order for rotated ring
        return [visualColors.bottom, visualColors.top]
    }
    
    private static func getVisualRingColors(
        habitColor: HabitIconColor,
        isCompleted: Bool,
        isExceeded: Bool,
        colorScheme: ColorScheme
    ) -> (top: Color, bottom: Color) {
        
        enum LocalHabitState {
            case inProgress, completed, exceeded
            
            init(isCompleted: Bool, isExceeded: Bool) {
                if isExceeded {
                    self = .exceeded
                } else if isCompleted {
                    self = .completed
                } else {
                    self = .inProgress
                }
            }
        }
        
        let habitState = LocalHabitState(isCompleted: isCompleted, isExceeded: isExceeded)
        
        switch habitState {
        case .completed:
            let lightGreen = Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.3, alpha: 1))
            let darkGreen = Color(#colorLiteral(red: 0.2, green: 0.55, blue: 0.05, alpha: 1))
            let visualTop = colorScheme == .dark ? darkGreen : lightGreen
            let visualBottom = colorScheme == .dark ? lightGreen : darkGreen
            return (top: visualTop, bottom: visualBottom)
            
        case .exceeded:
            let lightMint = Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.9, alpha: 1))
            let darkGreen = Color(#colorLiteral(red: 0.2, green: 0.55, blue: 0.05, alpha: 1))
            let visualTop = colorScheme == .dark ? darkGreen : lightMint
            let visualBottom = colorScheme == .dark ? lightMint : darkGreen
            return (top: visualTop, bottom: visualBottom)
            
        case .inProgress:
            let visualTop = colorScheme == .dark ? habitColor.darkColor : habitColor.lightColor
            let visualBottom = colorScheme == .dark ? habitColor.lightColor : habitColor.darkColor
            return (top: visualTop, bottom: visualBottom)
        }
    }
    
    static func getCompletedBarStyleStatic(for colorScheme: ColorScheme) -> AnyShapeStyle {
        let completedLightGreen = Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.3, alpha: 1))
        let completedDarkGreen = Color(#colorLiteral(red: 0.2, green: 0.55, blue: 0.05, alpha: 1))
        
        let topColor = colorScheme == .dark ? completedDarkGreen : completedLightGreen
        let bottomColor = colorScheme == .dark ? completedLightGreen : completedDarkGreen
        
        return AnyShapeStyle(
            LinearGradient(
                colors: [topColor, bottomColor],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    static func getExceededBarStyleStatic(for colorScheme: ColorScheme) -> AnyShapeStyle {
        let exceededLightMint = Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.9, alpha: 1))
        let exceededDarkGreen = Color(#colorLiteral(red: 0.2, green: 0.55, blue: 0.05, alpha: 1))
        
        let topColor = colorScheme == .dark ? exceededDarkGreen : exceededLightMint
        let bottomColor = colorScheme == .dark ? exceededLightMint : exceededDarkGreen
        
        return AnyShapeStyle(
            LinearGradient(
                colors: [topColor, bottomColor],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
