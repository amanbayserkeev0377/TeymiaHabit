import SwiftUI

// MARK: - Beautiful Button Style
struct BeautifulButtonStyle: ButtonStyle {
    let baseColor: Color
    let isEnabled: Bool
    let style: BeautifulButtonType
    
    init(color: Color, isEnabled: Bool = true, style: BeautifulButtonType = .primary) {
        self.baseColor = color
        self.isEnabled = isEnabled
        self.style = style
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(style.foregroundColor(isEnabled: isEnabled))
            .frame(maxWidth: .infinity)
            .frame(height: style.height)
            .background(
                RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                    .fill(
                        isEnabled 
                            ? style.backgroundGradient(from: baseColor)
                            : style.disabledGradient()
                    )
                    .shadow(
                        color: isEnabled ? baseColor.opacity(0.3) : Color.clear,
                        radius: isEnabled ? 8 : 0,
                        x: 0,
                        y: 4
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .scaleEffect(isEnabled ? 1.0 : 0.95)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
            .disabled(!isEnabled)
    }
}

// MARK: - Button Types
enum BeautifulButtonType {
    case primary      // Основные кнопки (Save, Complete)
    case secondary    // Второстепенные кнопки  
    case compact      // Компактные кнопки
    
    var height: CGFloat {
        switch self {
        case .primary: return 50
        case .secondary: return 44
        case .compact: return 38
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .primary: return 12
        case .secondary: return 10
        case .compact: return 8
        }
    }
    
    func foregroundColor(isEnabled: Bool) -> Color {
        return isEnabled ? .white : .secondary
    }
    
    func backgroundGradient(from color: Color) -> LinearGradient {
        switch self {
        case .primary:
            return LinearGradient(
                colors: [
                    color.opacity(0.9),  // Светлее
                    color,               // Основной
                    color.opacity(0.8)   // Темнее
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary, .compact:
            return LinearGradient(
                colors: [
                    color.opacity(0.8),
                    color
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    func disabledGradient() -> LinearGradient {
        return LinearGradient(
            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - View Extensions
extension View {
    /// Применяет красивый стиль кнопки с цветом приложения
    func beautifulButton(
        isEnabled: Bool = true, 
        style: BeautifulButtonType = .primary
    ) -> some View {
        self.buttonStyle(BeautifulButtonStyle(
            color: AppColorManager.shared.selectedColor.color,
            isEnabled: isEnabled,
            style: style
        ))
    }
    
    /// Применяет красивый стиль кнопки с цветом привычки
    func beautifulButton(
        habit: Habit, 
        isEnabled: Bool = true, 
        style: BeautifulButtonType = .primary
    ) -> some View {
        self.buttonStyle(BeautifulButtonStyle(
            color: habit.iconColor.color,
            isEnabled: isEnabled,
            style: style
        ))
    }
    
    /// Применяет красивый стиль кнопки с кастомным цветом
    func beautifulButton(
        color: Color, 
        isEnabled: Bool = true, 
        style: BeautifulButtonType = .primary
    ) -> some View {
        self.buttonStyle(BeautifulButtonStyle(
            color: color,
            isEnabled: isEnabled,
            style: style
        ))
    }
}
