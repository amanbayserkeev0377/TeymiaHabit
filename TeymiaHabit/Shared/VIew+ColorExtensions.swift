import SwiftUI

// MARK: - App Color Modifier
struct AppColorModifier: ViewModifier {
    @ObservedObject private var colorManager = AppColorManager.shared
    
    func body(content: Content) -> some View {
        content
            .tint(colorManager.selectedColor.color)
    }
}

// MARK: - App Gradient Modifier
struct AppGradientModifier: ViewModifier {
    @ObservedObject private var colorManager = AppColorManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle(colorManager.selectedColor.adaptiveGradient(for: colorScheme))
    }
}

// MARK: - Simplified Color Architecture
extension View {
    
    // MARK: - App Colors
    
    /// Глобальная тонировка (только tint, не foregroundStyle)
    func withAppColor() -> some View {
        modifier(AppColorModifier())
    }
    
    /// Применяет градиент приложения для foregroundStyle
    func withAppGradient() -> some View {
        modifier(AppGradientModifier())
    }
    
    // MARK: - Habit Colors
    
    /// Градиент привычки для текста и иконок
    func withHabitGradient(_ habit: Habit, colorScheme: ColorScheme) -> some View {
        self.foregroundStyle(habit.iconColor.adaptiveGradient(for: colorScheme))
    }
    
    /// Градиентный тинт для кнопок (через foregroundStyle)
    func withHabitGradientTint(_ habit: Habit, colorScheme: ColorScheme) -> some View {
        self.foregroundStyle(habit.iconColor.adaptiveGradient(for: colorScheme))
    }
    
    /// Обычный тинт привычки (для случаев, когда градиент не поддерживается)
    func withHabitTint(_ habit: Habit) -> some View {
        self.tint(habit.iconColor.color)
    }
        
    // MARK: - Static Color Getters
    
    static func appColor() -> Color {
        return AppColorManager.shared.selectedColor.color
    }
    
    static func habitColor(for habit: Habit) -> Color {
        return habit.iconColor.color
    }
}
