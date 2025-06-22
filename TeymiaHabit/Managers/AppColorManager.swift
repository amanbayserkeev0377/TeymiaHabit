import SwiftUI

final class AppColorManager: ObservableObject {
    static let shared = AppColorManager()
    
    // MARK: - Published Properties
    @Published private(set) var selectedColor: HabitIconColor
    @AppStorage("selectedAppColor") private var selectedColorId: String?
    
    // MARK: - Constants
    private struct ColorConstants {
        static let completedBaseGreen = Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1))
        
        struct Opacity {
            // Light theme gradient points
            static let lightStart: Double = 0.9
            static let lightFull: Double = 1.0
            static let lightMid: Double = 0.4
            static let lightEnd: Double = 0.6
            
            // Dark theme gradient points
            static let darkStart: Double = 0.7
            static let darkMid: Double = 0.8
            static let darkFull: Double = 1.0
        }
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
    
    /// Universal method for getting ring colors for any habit state
    /// Works for both regular and small rings
    func getRingColors(
        for habit: Habit?,
        isCompleted: Bool,
        isExceeded: Bool,
        colorScheme: ColorScheme
    ) -> [Color] {
        let habitState = HabitState(isCompleted: isCompleted, isExceeded: isExceeded)
        let baseColor = resolveBaseColor(for: habit)
        
        return generateColors(for: habitState, baseColor: baseColor, colorScheme: colorScheme)
    }
    
    /// Legacy method for backward compatibility
    func getSmallRingColors(
        for habit: Habit?,
        isCompleted: Bool,
        isExceeded: Bool,
        colorScheme: ColorScheme
    ) -> [Color] {
        // Same logic as regular rings - no need for separate implementation
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
    
    func resolveBaseColor(for habit: Habit?) -> Color {
        return habit?.iconColor.color ?? selectedColor.color
    }
    
    func generateColors(
        for state: HabitState,
        baseColor: Color,
        colorScheme: ColorScheme
    ) -> [Color] {
        switch state {
        case .completed:
            return createCompletedGradient(colorScheme: colorScheme)
        case .exceeded:
            return createExceededGradient(colorScheme: colorScheme)
        case .inProgress:
            return createProgressGradient(baseColor: baseColor, colorScheme: colorScheme)
        }
    }
    
    func createCompletedGradient(colorScheme: ColorScheme) -> [Color] {
        let green = ColorConstants.completedBaseGreen
        let opacity = ColorConstants.Opacity.self
        
        return colorScheme == .dark
            ? [green.opacity(opacity.darkStart), green.opacity(opacity.darkMid), green, green, green.opacity(opacity.darkStart)]
            : [green.opacity(opacity.lightStart), green, green.opacity(opacity.lightMid), green.opacity(opacity.lightEnd), green.opacity(opacity.lightStart)]
    }
    
    func createExceededGradient(colorScheme: ColorScheme) -> [Color] {
        let green = ColorConstants.completedBaseGreen
        let mint = HabitIconColor.mint.color
        let opacity = ColorConstants.Opacity.self
        
        return colorScheme == .dark
            ? [green.opacity(opacity.darkStart), green.opacity(opacity.darkMid), mint, mint, green.opacity(opacity.darkStart)]
            : [green.opacity(opacity.lightStart), green, mint.opacity(opacity.lightEnd), mint.opacity(opacity.darkMid), green.opacity(opacity.lightStart)]
    }
    
    func createProgressGradient(baseColor: Color, colorScheme: ColorScheme) -> [Color] {
        let opacity = ColorConstants.Opacity.self
        
        return colorScheme == .dark
            ? [baseColor.opacity(opacity.darkStart), baseColor.opacity(opacity.darkMid), baseColor, baseColor, baseColor.opacity(opacity.darkStart)]
            : [baseColor.opacity(opacity.lightStart), baseColor, baseColor.opacity(opacity.lightMid), baseColor.opacity(opacity.lightEnd), baseColor.opacity(opacity.lightStart)]
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
