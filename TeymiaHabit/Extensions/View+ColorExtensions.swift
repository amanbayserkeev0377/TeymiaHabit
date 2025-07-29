import SwiftUI

// MARK: - App Color Modifier

/// Modifier that applies the global app color as tint
struct AppColorModifier: ViewModifier {
    @ObservedObject private var colorManager = AppColorManager.shared
    
    func body(content: Content) -> some View {
        content
            .tint(colorManager.selectedColor.color)
    }
}

// MARK: - App Gradient Modifier

/// Modifier that applies the global app color as gradient foreground style
struct AppGradientModifier: ViewModifier {
    @ObservedObject private var colorManager = AppColorManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle(colorManager.selectedColor.adaptiveGradient(for: colorScheme))
    }
}

// MARK: - Color Architecture Extensions

extension View {
    
    // MARK: - App Colors
    
    /// Applies global app color as tint (not foregroundStyle)
    /// Use for buttons, navigation elements, and accent colors
    func withAppColor() -> some View {
        modifier(AppColorModifier())
    }
    
    /// Applies app color gradient for foregroundStyle
    /// Use for text and icons that need gradient appearance
    func withAppGradient() -> some View {
        modifier(AppGradientModifier())
    }
    
    // MARK: - Habit Colors
    
    /// Applies habit color gradient for text and icons
    /// - Parameters:
    ///   - habit: Habit containing the color information
    ///   - colorScheme: Current color scheme for adaptive colors
    func withHabitGradient(_ habit: Habit, colorScheme: ColorScheme) -> some View {
        self.foregroundStyle(habit.iconColor.adaptiveGradient(for: colorScheme))
    }
    
    /// Applies habit color gradient as tint for buttons
    /// - Parameters:
    ///   - habit: Habit containing the color information
    ///   - colorScheme: Current color scheme for adaptive colors
    func withHabitGradientTint(_ habit: Habit, colorScheme: ColorScheme) -> some View {
        self.foregroundStyle(habit.iconColor.adaptiveGradient(for: colorScheme))
    }
    
    /// Applies habit color as standard tint (fallback for gradient-unsupported cases)
    /// - Parameter habit: Habit containing the color information
    func withHabitTint(_ habit: Habit) -> some View {
        self.tint(habit.iconColor.color)
    }
        
    // MARK: - Static Color Getters
    
    /// Gets the current global app color
    /// - Returns: Current app accent color
    static func appColor() -> Color {
        return AppColorManager.shared.selectedColor.color
    }
    
    /// Gets the color for a specific habit
    /// - Parameter habit: Habit to get color for
    /// - Returns: Habit's assigned color
    static func habitColor(for habit: Habit) -> Color {
        return habit.iconColor.color
    }
}
