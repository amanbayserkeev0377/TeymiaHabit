import SwiftUI

// MARK: - App Color Modifier (восстанавливаем реактивность)
struct AppColorModifier: ViewModifier {
    @ObservedObject private var colorManager = AppColorManager.shared
    
    func body(content: Content) -> some View {
        content
            .tint(colorManager.selectedColor.color)
    }
}

// MARK: - Simplified Color Architecture  
extension View {
    
    // MARK: - App Colors (реактивные для общих элементов)
    
    /// Глобальная тонировка с реактивным обновлением
    func withAppColor() -> some View {
        modifier(AppColorModifier())
    }
    
    /// Применяет цвет приложения для foregroundStyle
    func withAppForeground() -> some View {
        self.foregroundStyle(AppColorManager.shared.selectedColor.color)
    }
    
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
