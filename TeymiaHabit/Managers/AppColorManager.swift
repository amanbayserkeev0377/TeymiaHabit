import SwiftUI

final class AppColorManager: ObservableObject {
    static let shared = AppColorManager()
    
    // MARK: - Published Properties
    @Published private(set) var selectedColor: HabitIconColor
    @AppStorage("selectedAppColor") private var selectedColorId: String?
    
    // MARK: - Constants
    private struct ColorConstants {
        static let completedLightGreen = Color(#colorLiteral(red: 0.4980392157, green: 0.9333333333, blue: 0.29019607843, alpha: 1))
        static let completedDarkGreen = Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1))
        
        static let exceededLightMint = Color(#colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1))
        static let exceededDarkMint = Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1))
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
    
    /// НОВЫЙ метод для получения чистых цветов кольца (адаптивная логика по темам)
    func getRingColors(
        for habit: Habit?,
        isCompleted: Bool,
        isExceeded: Bool,
        colorScheme: ColorScheme
    ) -> [Color] {
        let habitState = HabitState(isCompleted: isCompleted, isExceeded: isExceeded)
        
        switch habitState {
        case .completed:
            // Чистый зеленый градиент (адаптивный)
            let light = ColorConstants.completedLightGreen
            let dark = ColorConstants.completedDarkGreen
            
            return colorScheme == .dark
                ? [light, dark, dark, light]       // Темная тема: light→dark→light
                : [dark, light, light, dark]       // Светлая тема: dark→light→dark
            
        case .exceeded:
            // Чистый мятный градиент (адаптивный)
            let light = ColorConstants.exceededLightMint
            let dark = ColorConstants.exceededDarkMint
            
            return colorScheme == .dark
                ? [light, dark, dark, light]
                : [dark, light, light, dark]
            
        case .inProgress:
            // Специальная логика для primary цвета
            let habitColor = habit?.iconColor ?? selectedColor
            
            if habitColor == .primary {
                // Для primary создаем черно-белый градиент по темам
                return colorScheme == .dark
                    ? [Color.white, Color.gray, Color.gray, Color.white]           // Темная тема: белый градиент
                    : [Color.black, Color.gray, Color.gray, Color.black]          // Светлая тема: черный градиент
            } else {
                // Для остальных цветов используем обычную логику
                let light = habitColor.lightColor
                let dark = habitColor.darkColor
                
                return colorScheme == .dark
                    ? [light, dark, dark, light]        // Темная тема: светлее→темнее→светлее
                    : [dark, light, light, dark]         // Светлая тема: темнее→светлее→темнее
            }
        }
    }
    
    /// Legacy method - теперь просто вызывает новый метод
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
    
    /// Метод для получения чистого градиента кнопок
    func getButtonGradient(for habit: Habit?) -> LinearGradient {
        let habitColor = habit?.iconColor ?? selectedColor
        return habitColor.gradient
    }
}

// MARK: - Private Helpers (упрощенные)
private extension AppColorManager {
    
    func loadSavedColor() {
        guard let savedColorId = selectedColorId,
              let savedColor = HabitIconColor(rawValue: savedColorId) else {
            return
        }
        selectedColor = savedColor
    }
}

// MARK: - Supporting Types (упрощенные)
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
