import SwiftUI

final class AppColorManager: ObservableObject {
    static let shared = AppColorManager()
    
    // App color properties
    @Published private(set) var selectedColor: HabitIconColor
    @AppStorage("selectedAppColor") private var selectedColorId: String?
    
    private let availableColors: [HabitIconColor] = [
        .primary,
        .red,
        .orange,
        .yellow,
        .mint,
        .green,
        .blue,
        .purple,
        .softLavender,
        .pink,
        .sky,
        .brown,
        .gray,
        .colorPicker
    ]
    
    private init() {
        selectedColor = .primary
        
        // Load saved app color
        if let savedColorId = selectedColorId,
           let color = HabitIconColor(rawValue: savedColorId) {
            selectedColor = color
        }
    }
    
    // MARK: - Public Methods
    
    func setAppColor(_ color: HabitIconColor) {
        selectedColor = color
        selectedColorId = color.rawValue
    }
    
    func getAvailableColors() -> [HabitIconColor] {
        return availableColors
    }
    
    // MARK: - Ring Colors (упрощенная логика)
    
    /// Получить цвета для кольца прогресса привычки
    /// - Parameters:
    ///   - habit: Привычка (если nil - используется app color)
    ///   - isCompleted: Завершена ли привычка
    ///   - isExceeded: Превышена ли цель
    ///   - colorScheme: Текущая тема (передается из SwiftUI View)
    /// - Returns: Массив цветов для градиента кольца
    func getRingColors(for habit: Habit?, isCompleted: Bool, isExceeded: Bool, colorScheme: ColorScheme) -> [Color] {
        // Завершенные привычки всегда зеленые
        if isCompleted || isExceeded {
            return getCompletedColors(isExceeded: isExceeded, colorScheme: colorScheme)
        }
        
        // Для незавершенных - используем цвет привычки или app color как fallback
        let baseColor = habit?.iconColor.color ?? selectedColor.color
        return generateProgressColors(from: baseColor, colorScheme: colorScheme)
    }
    
    /// Получить цвета для маленьких колец (например, в календаре)
    /// Использует ту же логику что и большие кольца
    func getSmallRingColors(for habit: Habit?, isCompleted: Bool, isExceeded: Bool, colorScheme: ColorScheme) -> [Color] {
        // Завершенные привычки всегда зеленые
        if isCompleted || isExceeded {
            return getCompletedColors(isExceeded: isExceeded, colorScheme: colorScheme)
        }
        
        // Для незавершенных - используем цвет привычки или app color как fallback
        let baseColor = habit?.iconColor.color ?? selectedColor.color
        return generateProgressColors(from: baseColor, colorScheme: colorScheme)
    }
    
    // MARK: - Private Helper Methods
    
    /// Зеленые цвета для завершенных привычек
    private func getCompletedColors(isExceeded: Bool, colorScheme: ColorScheme) -> [Color] {
        if isExceeded {
            let baseGreen = Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1))
            let habitMintColor = HabitIconColor.mint.color
            
            if colorScheme == .dark {
                return [
                    baseGreen.opacity(0.7),
                    baseGreen.opacity(0.8),
                    habitMintColor,
                    habitMintColor,
                    baseGreen.opacity(0.7)
                ]
            } else {
                return [
                    baseGreen.opacity(0.9),
                    baseGreen,
                    habitMintColor.opacity(0.6),
                    habitMintColor.opacity(0.8),
                    baseGreen.opacity(0.9)
                ]
            }
        } else {
            let baseGreen = Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1))
            
            if colorScheme == .dark {
                return [
                    baseGreen.opacity(0.7),
                    baseGreen.opacity(0.8),
                    baseGreen,
                    baseGreen,
                    baseGreen.opacity(0.7)
                ]
            } else {
                return [
                    baseGreen.opacity(0.9),
                    baseGreen,
                    baseGreen.opacity(0.4),
                    baseGreen.opacity(0.6),
                    baseGreen.opacity(0.9)
                ]
            }
        }
    }
    
    
    /// Генерация градиента для колец прогресса
    /// В темной теме - отзеркаленный градиент с другими opacity
    private func generateProgressColors(from baseColor: Color, colorScheme: ColorScheme) -> [Color] {
        if colorScheme == .dark {
            // Темная тема: отзеркаленный градиент с мягкими opacity
            return [
                baseColor.opacity(0.7),
                baseColor.opacity(0.8),
                baseColor,
                baseColor,
                baseColor.opacity(0.7)
            ]
        } else {
            // Светлая тема: как было
            return [
                baseColor.opacity(0.9),
                baseColor,
                baseColor.opacity(0.4),
                baseColor.opacity(0.6),
                baseColor.opacity(0.9)
            ]
        }
    }

}
