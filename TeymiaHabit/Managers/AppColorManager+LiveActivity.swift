import SwiftUI

// MARK: - LiveActivity-only Color Manager
struct LiveActivityColorManager {
    
    /// Get ring colors for LiveActivity - completely independent
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
            let lightColor = habitColor.lightColor
            let darkColor = habitColor.darkColor
            
            let visualTop = colorScheme == .dark ? darkColor : lightColor
            let visualBottom = colorScheme == .dark ? lightColor : darkColor
            
            return (top: visualTop, bottom: visualBottom)
        }
    }
    
    /// Static completed bars gradient
    static func getCompletedBarStyle(for colorScheme: ColorScheme) -> AnyShapeStyle {
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
    
    /// Static exceeded bars gradient
    static func getExceededBarStyle(for colorScheme: ColorScheme) -> AnyShapeStyle {
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
