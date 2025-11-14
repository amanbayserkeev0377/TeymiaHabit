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
            .foregroundStyle(colorManager.selectedColor.color.gradient)
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
    
    func withHabitGradient(_ habit: Habit) -> some View {
        self.foregroundStyle(habit.iconColor.color.gradient)
    }
    
    func withHabitGradientTint(_ habit: Habit) -> some View {
        self.foregroundStyle(habit.iconColor.color.gradient)
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
