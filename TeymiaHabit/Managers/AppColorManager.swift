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
    /// - Returns: Массив цветов для градиента кольца
    func getRingColors(for habit: Habit?, isCompleted: Bool, isExceeded: Bool) -> [Color] {
        // Завершенные привычки всегда зеленые
        if isCompleted || isExceeded {
            return getCompletedColors(isExceeded: isExceeded)
        }
        
        // Для незавершенных - используем цвет привычки или app color как fallback
        let baseColor = habit?.iconColor.color ?? selectedColor.color
        return generateProgressColors(from: baseColor)
    }
    
    /// Получить цвета для маленьких колец (например, в календаре)
    /// Логика та же, но с другим градиентом для лучшей видимости
    func getSmallRingColors(for habit: Habit?, isCompleted: Bool, isExceeded: Bool) -> [Color] {
        // Завершенные привычки всегда зеленые
        if isCompleted || isExceeded {
            return getCompletedColors(isExceeded: isExceeded)
        }
        
        // Для незавершенных - используем цвет привычки или app color как fallback
        let baseColor = habit?.iconColor.color ?? selectedColor.color
        return generateSmallRingColors(from: baseColor)
    }
    
    // MARK: - Private Helper Methods
    
    /// Зеленые цвета для завершенных привычек (неизменяемые)
    private func getCompletedColors(isExceeded: Bool) -> [Color] {
        if isExceeded {
            // Более темный зеленый для превышенных целей
            return [
                Color(#colorLiteral(red: 0.1803921569, green: 0.5450980392, blue: 0.3411764706, alpha: 1)),
                Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1)),
                Color(#colorLiteral(red: 0.1411764706, green: 0.4274509804, blue: 0.2666666667, alpha: 1)),
                Color(#colorLiteral(red: 0.2470588235, green: 0.6196078431, blue: 0.1960784314, alpha: 1)),
                Color(#colorLiteral(red: 0.1803921569, green: 0.5450980392, blue: 0.3411764706, alpha: 1))
            ]
        } else {
            // Обычный зеленый для завершенных
            return [
                Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1)),
                Color(#colorLiteral(red: 0.1803921569, green: 0.5450980392, blue: 0.3411764706, alpha: 1)),
                Color(#colorLiteral(red: 0.8196078431, green: 1, blue: 0.8352941176, alpha: 1)),
                Color(#colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)),
                Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1))
            ]
        }
    }
    
    /// Генерация градиента для больших колец прогресса
    private func generateProgressColors(from baseColor: Color) -> [Color] {
        return [
            baseColor.opacity(0.9),  // Темное начало
            baseColor,               // Полная яркость
            baseColor.opacity(0.2),  // Очень светлый
            baseColor.opacity(0.5),  // Средний
            baseColor.opacity(0.9)   // Обратно к темному для плавного градиента
        ]
    }
    
    /// Генерация градиента для маленьких колец (календарь, etc)
    private func generateSmallRingColors(from baseColor: Color) -> [Color] {
        return [
            baseColor.opacity(0.3),  // Светлое начало
            baseColor.opacity(0.5),  // Средний
            baseColor.opacity(0.9),  // Темный
            baseColor,               // Полная яркость
            baseColor.opacity(0.3)   // Обратно к светлому
        ]
    }
}
