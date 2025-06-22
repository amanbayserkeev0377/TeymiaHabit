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
            .foregroundStyle(style.foregroundColor(for: baseColor, isEnabled: isEnabled))
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
    
    // ИСПРАВЛЕНО: умный выбор цвета текста на основе контраста
    func foregroundColor(for backgroundColor: Color, isEnabled: Bool) -> Color {
        guard isEnabled else {
            return .secondary
        }
        
        // Проверяем контраст с фоном
        if backgroundColor.isLight {
            return .black  // Темный текст на светлом фоне
        } else {
            return .white  // Светлый текст на темном фоне
        }
    }
    
    func backgroundGradient(from color: Color) -> LinearGradient {
        switch self {
        case .primary:
            return LinearGradient(
                colors: [
                    color.opacity(0.5),  // Светлее
                    color.opacity(0.7),  // Средний
                    color.opacity(0.8)   // Темнее
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary, .compact:
            return LinearGradient(
                colors: [
                    color.opacity(0.5),  // Светлее
                    color.opacity(0.7),  // Средний
                    color.opacity(0.8)   // Темнее
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
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

// MARK: - Color Extensions
extension Color {
    // Определяем, светлый ли цвет
    var isLight: Bool {
        // Конвертируем Color в UIColor для получения RGB компонентов
        let uiColor = UIColor(self)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Используем стандартную формулу для определения яркости
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        
        // Если яркость больше 0.5, считаем цвет светлым
        return luminance > 0.5
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
