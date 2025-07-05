import SwiftUI

// MARK: - Button Style Parameters (УПРОЩЕННЫЕ)
struct ButtonStyleParameters {
    let habitColor: HabitIconColor
    let lightOpacity: Double
    let darkOpacity: Double
    let isEnabled: Bool
    let styleType: BeautifulButtonType
}

// MARK: - Beautiful Button Style (УПРОЩЕННЫЙ)
struct BeautifulButtonStyle: ButtonStyle {
    let parameters: ButtonStyleParameters
    @Environment(\.colorScheme) private var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(parameters.isEnabled ? .white : .secondary)  // ✅ ПРОСТО!
            .frame(maxWidth: .infinity)
            .frame(height: parameters.styleType.height)
            .background(
                LinearGradient(
                    colors: parameters.isEnabled ? gradientColors : [Color.gray.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: parameters.styleType.cornerRadius)
                    .stroke(strokeColor, lineWidth: 0.7)
            )
            .clipShape(RoundedRectangle(cornerRadius: parameters.styleType.cornerRadius))
            .shadow(
                color: parameters.isEnabled ? shadowColor : .clear,
                radius: parameters.isEnabled ? shadowRadius : 0,
                x: 0, y: parameters.isEnabled ? shadowOffset : 0
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .scaleEffect(parameters.isEnabled ? 1.0 : 0.95)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.1), value: parameters.isEnabled)
            .disabled(!parameters.isEnabled)
    }
    
    // MARK: - ✅ УПРОЩЕННЫЕ свойства
    
    private var gradientColors: [Color] {
        return colorScheme == .dark ? [
            parameters.habitColor.darkColor.opacity(parameters.darkOpacity),
            parameters.habitColor.lightColor.opacity(parameters.lightOpacity),
        ] : [
            parameters.habitColor.lightColor.opacity(parameters.lightOpacity),
            parameters.habitColor.darkColor.opacity(parameters.darkOpacity),
        ]
    }
    
    private var strokeColor: Color {
        return Color.primary.opacity(0.2)
    }
    
    private var shadowColor: Color {
        return Color.primary.opacity(0.15)
    }
    
    private var shadowRadius: CGFloat {
        return colorScheme == .dark ? 0 : 4
    }
    
    private var shadowOffset: CGFloat {
        return colorScheme == .dark ? 0 : 3
    }
}

// MARK: - Button Types (БЕЗ ИЗМЕНЕНИЙ)
enum BeautifulButtonType {
    case primary, secondary, compact
    
    var height: CGFloat {
        switch self {
        case .primary: return 56
        case .secondary: return 44
        case .compact: return 38
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .primary: return 16
        case .secondary: return 12
        case .compact: return 10
        }
    }
}

// MARK: - ✅ УПРОЩЕННЫЕ View Extensions

extension View {
    
    // MARK: - Основные методы (НУЖНЫЕ)
    
    func beautifulButton(
        isEnabled: Bool = true,
        style: BeautifulButtonType = .primary,
        lightOpacity: Double = 1.0,
        darkOpacity: Double = 1.0
    ) -> some View {
        let parameters = ButtonStyleParameters(
            habitColor: AppColorManager.shared.selectedColor,
            lightOpacity: lightOpacity,
            darkOpacity: darkOpacity,
            isEnabled: isEnabled,
            styleType: style
        )
        return self.buttonStyle(BeautifulButtonStyle(parameters: parameters))
    }
    
    func beautifulButton(
        habit: Habit,
        isEnabled: Bool = true,
        style: BeautifulButtonType = .primary,
        lightOpacity: Double = 1.0,
        darkOpacity: Double = 1.0
    ) -> some View {
        let parameters = ButtonStyleParameters(
            habitColor: habit.iconColor,
            lightOpacity: lightOpacity,
            darkOpacity: darkOpacity,
            isEnabled: isEnabled,
            styleType: style
        )
        return self.buttonStyle(BeautifulButtonStyle(parameters: parameters))
    }
    
    func beautifulButton(
        habitColor: HabitIconColor,
        isEnabled: Bool = true,
        style: BeautifulButtonType = .primary,
        lightOpacity: Double = 1.0,
        darkOpacity: Double = 1.0
    ) -> some View {
        let parameters = ButtonStyleParameters(
            habitColor: habitColor,
            lightOpacity: lightOpacity,
            darkOpacity: darkOpacity,
            isEnabled: isEnabled,
            styleType: style
        )
        return self.buttonStyle(BeautifulButtonStyle(parameters: parameters))
    }
}
