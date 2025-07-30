import SwiftUI

// MARK: - Modifiers

struct AppColorModifier: ViewModifier {
    @ObservedObject private var colorManager = AppColorManager.shared
    
    func body(content: Content) -> some View {
        content
            .tint(colorManager.selectedColor.color)
    }
}

struct AppGradientModifier: ViewModifier {
    @ObservedObject private var colorManager = AppColorManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle(colorManager.selectedColor.adaptiveGradient(for: colorScheme))
    }
}

// MARK: - Extensions

extension View {
    func withAppColor() -> some View {
        modifier(AppColorModifier())
    }
    
    func withAppGradient() -> some View {
        modifier(AppGradientModifier())
    }
    
    func withHabitGradient(_ habit: Habit, colorScheme: ColorScheme) -> some View {
        self.foregroundStyle(habit.iconColor.adaptiveGradient(for: colorScheme))
    }
    
    func withHabitGradientTint(_ habit: Habit, colorScheme: ColorScheme) -> some View {
        self.foregroundStyle(habit.iconColor.adaptiveGradient(for: colorScheme))
    }
    
    func withHabitTint(_ habit: Habit) -> some View {
        self.tint(habit.iconColor.color)
    }
    
    static func appColor() -> Color {
        AppColorManager.shared.selectedColor.color
    }
    
    static func habitColor(for habit: Habit) -> Color {
        habit.iconColor.color
    }
}
