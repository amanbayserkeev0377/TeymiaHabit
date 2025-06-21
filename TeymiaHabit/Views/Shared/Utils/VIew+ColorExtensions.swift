import SwiftUI

// MARK: - Simplified Color Architecture  
extension View {
    
    // MARK: - Habit Colors (переопределяют глобальный тинт)
    
    /// Цвет привычки для текста и иконок
    func withHabitColor(_ habit: Habit) -> some View {
        self.foregroundStyle(habit.iconColor.color)
    }
    
    /// Тинт привычки для кнопок и интерактивных элементов  
    func withHabitTint(_ habit: Habit) -> some View {
        self.tint(habit.iconColor.color)
    }
    
    /// Фон цвета привычки
    func withHabitBackground(_ habit: Habit, opacity: Double = 0.1) -> some View {
        self.background(habit.iconColor.color.opacity(opacity))
    }
    
    // MARK: - Static Color Getters (для computed properties)
    
    static func appColor() -> Color {
        return AppColorManager.shared.selectedColor.color
    }
    
    static func habitColor(for habit: Habit) -> Color {
        return habit.iconColor.color
    }
}
