import SwiftUI

// MARK: - LiveActivity Color Manager

/// Standalone color manager for LiveActivity extensions
/// Duplicates colors from main AppColorManager to avoid dependencies
struct LiveActivityColorManager {
    
    // MARK: - Color Constants
    private static let completedLightGreen = Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.3, alpha: 1))
    private static let completedDarkGreen = Color(#colorLiteral(red: 0.2, green: 0.55, blue: 0.05, alpha: 1))
    private static let exceededLightMint = Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.9, alpha: 1))
    private static let exceededDarkGreen = Color(#colorLiteral(red: 0.2, green: 0.55, blue: 0.05, alpha: 1))
    
    // MARK: - Ring Colors
    
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
        
        return [visualColors.bottom, visualColors.top]
    }
    
    private static func getVisualRingColors(
        habitColor: HabitIconColor,
        isCompleted: Bool,
        isExceeded: Bool,
        colorScheme: ColorScheme
    ) -> (top: Color, bottom: Color) {
        
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
        
        let habitState = HabitState(isCompleted: isCompleted, isExceeded: isExceeded)
        
        switch habitState {
        case .completed:
            let visualTop = colorScheme == .dark ? completedDarkGreen : completedLightGreen
            let visualBottom = colorScheme == .dark ? completedLightGreen : completedDarkGreen
            return (top: visualTop, bottom: visualBottom)
            
        case .exceeded:
            let visualTop = colorScheme == .dark ? exceededDarkGreen : exceededLightMint
            let visualBottom = colorScheme == .dark ? exceededLightMint : exceededDarkGreen
            return (top: visualTop, bottom: visualBottom)
            
        case .inProgress:
            let visualTop = colorScheme == .dark ? habitColor.darkColor : habitColor.lightColor
            let visualBottom = colorScheme == .dark ? habitColor.lightColor : habitColor.darkColor
            return (top: visualTop, bottom: visualBottom)
        }
    }
    
    // MARK: - Bar Styles
    
    static func getCompletedBarStyle(for colorScheme: ColorScheme) -> AnyShapeStyle {
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
    
    static func getExceededBarStyle(for colorScheme: ColorScheme) -> AnyShapeStyle {
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
