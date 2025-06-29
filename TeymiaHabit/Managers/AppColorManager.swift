import SwiftUI

final class AppColorManager: ObservableObject {
    static let shared = AppColorManager()
    
    // MARK: - Published Properties
    @Published private(set) var selectedColor: HabitIconColor
    @AppStorage("selectedAppColor") private var selectedColorId: String?
    
    // MARK: - Constants
    private struct ColorConstants {
        static let completedLightGreen = Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.3, alpha: 1))
        static let completedDarkGreen = Color(#colorLiteral(red: 0.2, green: 0.55, blue: 0.05, alpha: 1))
        
        static let exceededLightMint = Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.9, alpha: 1))
        static let exceededDarkGreen = Color(#colorLiteral(red: 0.2, green: 0.55, blue: 0.05, alpha: 1))
    }
    
    private let availableColors: [HabitIconColor] = [
        .primary, .red, .orange, .yellow, .mint, .green, .blue, .purple,
        .softLavender, .pink, .sky, .brown, .gray, .colorPicker
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
        return availableColors
    }
    
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
    /// Returns (top: Color, bottom: Color) as displayed to user
    private func getVisualRingColors(
        for habit: Habit?,
        isCompleted: Bool,
        isExceeded: Bool,
        colorScheme: ColorScheme
    ) -> (top: Color, bottom: Color) {
        let habitState = HabitState(isCompleted: isCompleted, isExceeded: isExceeded)
        
        switch habitState {
        case .completed:
            let lightGreen = ColorConstants.completedLightGreen
            let darkGreen = ColorConstants.completedDarkGreen
            
            // Visual logic: light theme = light top → dark bottom, dark theme = dark top → light bottom
            let visualTop = colorScheme == .dark ? darkGreen : lightGreen
            let visualBottom = colorScheme == .dark ? lightGreen : darkGreen
            
            return (top: visualTop, bottom: visualBottom)
            
        case .exceeded:
            let lightMint = ColorConstants.exceededLightMint
            let darkGreen = ColorConstants.exceededDarkGreen
            
            let visualTop = colorScheme == .dark ? darkGreen : lightMint
            let visualBottom = colorScheme == .dark ? lightMint : darkGreen
            
            return (top: visualTop, bottom: visualBottom)
            
        case .inProgress:
            let habitColor = habit?.iconColor ?? selectedColor
            
            let lightColor = habitColor.lightColor
            let darkColor = habitColor.darkColor
            
            let visualTop = colorScheme == .dark ? darkColor : lightColor
            let visualBottom = colorScheme == .dark ? lightColor : darkColor
            
            return (top: visualTop, bottom: visualBottom)
        }
    }
    
    /// Legacy method - delegates to new implementation
    func getSmallRingColors(
        for habit: Habit?,
        isCompleted: Bool,
        isExceeded: Bool,
        colorScheme: ColorScheme
    ) -> [Color] {
        return getRingColors(
            for: habit,
            isCompleted: isCompleted,
            isExceeded: isExceeded,
            colorScheme: colorScheme
        )
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
    
    /// Represents the current state of a habit for color determination
    enum HabitState {
        case inProgress  // Default state for incomplete habits
        case completed   // Habit is completed
        case exceeded    // Habit goal is exceeded
        
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

// MARK: - 📝 DEVELOPER DOCUMENTATION

/*
 🎯 RING GRADIENT SYSTEM EXPLANATION:
 
 WHY THE COMPLEXITY?
 ProgressRingCircle uses LinearGradient with .leading → .trailing direction and -90° rotation.
 This rotation is necessary so the ring starts at 12 o'clock (top) instead of 3 o'clock (right).
 
 COORDINATE TRANSFORMATION:
 - Without rotation: .leading = left, .trailing = right
 - With -90° rotation: .leading = top, .trailing = bottom (visually)
 - Gradient array [0, 1] maps to [.leading, .trailing] = [visual top, visual bottom]
 - BUT we want to think in visual terms: [visual bottom, visual top]
 
 SOLUTION:
 1. getVisualRingColors() - Think in visual terms: what does user see?
 2. getRingColors() - Convert visual order to gradient array order
 3. Result: Code reads naturally, works correctly
 
 VISUAL LOGIC (consistent across all states):
 - Light theme: light top → dark bottom
 - Dark theme: dark top → light bottom
 
 This creates natural depth perception and follows iOS design principles.
 */
