import SwiftUI

// MARK: - Button Style Parameters (передаем параметры, не готовую конфигурацию)
struct ButtonStyleParameters {
    enum ButtonType {
        case neutral(primaryColor: Color, secondaryColor: Color)
        case colored(habitColor: HabitIconColor, opacity: Double)
        case legacy(color: Color)
    }
    
    let type: ButtonType
    let isEnabled: Bool
    let styleType: BeautifulButtonType
}

// MARK: - Beautiful Button Style (чистая архитектура)
struct BeautifulButtonStyle: ButtonStyle {
    let parameters: ButtonStyleParameters
    
    @Environment(\.colorScheme) private var colorScheme // Правильный доступ к теме!
    
    // Главный инициализатор - только параметры, без логики
    init(parameters: ButtonStyleParameters) {
        self.parameters = parameters
    }
    
    func makeBody(configuration: Configuration) -> some View {
        let config = createConfiguration() // Здесь уже есть доступ к colorScheme!
        
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(parameters.isEnabled ? textColor(for: config) : .secondary)
            .frame(maxWidth: .infinity)
            .frame(height: parameters.styleType.height)
            .background(
                LinearGradient(
                    colors: parameters.isEnabled ? config.gradientColors : [Color.gray.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: parameters.styleType.cornerRadius)
                    .stroke(
                        parameters.isEnabled ? config.strokeColor : Color.gray.opacity(0.3),
                        lineWidth: config.strokeWidth
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: parameters.styleType.cornerRadius))
            .shadow(
                color: parameters.isEnabled ? config.shadowColor : .clear,
                radius: parameters.isEnabled ? config.shadowRadius : 0,
                x: 0,
                y: parameters.isEnabled ? config.shadowOffset : 0
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .scaleEffect(parameters.isEnabled ? 1.0 : 0.95)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: parameters.isEnabled)
            .disabled(!parameters.isEnabled)
    }
    
    // MARK: - Private Helpers (с доступом к правильному colorScheme)
    
    private func createConfiguration() -> ButtonConfiguration {
        switch parameters.type {
        case .neutral(let primaryColor, let secondaryColor):
            return createNeutralConfiguration(primaryColor: primaryColor, secondaryColor: secondaryColor)
            
        case .colored(let habitColor, let opacity):
            return createColoredConfiguration(habitColor: habitColor, opacity: opacity)
            
        case .legacy(let color):
            return createLegacyConfiguration(color: color)
        }
    }
    
    private func createNeutralConfiguration(primaryColor: Color, secondaryColor: Color) -> ButtonConfiguration {
        return ButtonConfiguration(
            gradientColors: colorScheme == .dark ? [
                secondaryColor,  // В темной теме: инвертируем
                primaryColor
            ] : [
                primaryColor,    // В светлой теме: обычно
                secondaryColor
            ],
            strokeColor: colorScheme == .dark
                ? Color.white.opacity(0.2)
                : Color.black.opacity(0.15),
            strokeWidth: 0.8,
            shadowColor: colorScheme == .dark
                ? .clear
                : Color.black.opacity(0.2),
            shadowRadius: colorScheme == .dark ? 0 : 8,
            shadowOffset: colorScheme == .dark ? 0 : 4
        )
    }
    
    private func createColoredConfiguration(habitColor: HabitIconColor, opacity: Double) -> ButtonConfiguration {
        // Специальная логика для primary цвета
        if habitColor == .primary {
            return ButtonConfiguration(
                gradientColors: colorScheme == .dark
                    ? [Color.white.opacity(opacity), Color.gray.opacity(opacity)]
                    : [Color.black.opacity(opacity), Color.gray.opacity(opacity)],
                strokeColor: colorScheme == .dark
                    ? Color.white.opacity(0.15)
                    : Color.black.opacity(0.12),
                strokeWidth: 0.7,
                shadowColor: colorScheme == .dark
                    ? .clear
                    : Color.black.opacity(0.1),
                shadowRadius: colorScheme == .dark ? 0 : 6,
                shadowOffset: colorScheme == .dark ? 0 : 3
            )
        } else {
            // Для остальных цветов используем чистые lightColor/darkColor
            return ButtonConfiguration(
                gradientColors: [
                    habitColor.lightColor.opacity(opacity),
                    habitColor.darkColor.opacity(opacity)
                ],
                strokeColor: colorScheme == .dark
                    ? Color.white.opacity(0.15)
                    : Color.black.opacity(0.12),
                strokeWidth: 0.7,
                shadowColor: colorScheme == .dark
                    ? .clear
                    : Color.black.opacity(0.1),
                shadowRadius: colorScheme == .dark ? 0 : 6,
                shadowOffset: colorScheme == .dark ? 0 : 3
            )
        }
    }
    
    private func createLegacyConfiguration(color: Color) -> ButtonConfiguration {
        return ButtonConfiguration(
            gradientColors: [color.opacity(0.5), color.opacity(0.8)],
            strokeColor: colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.12),
            strokeWidth: 0.7,
            shadowColor: colorScheme == .dark ? .clear : Color.black.opacity(0.1),
            shadowRadius: colorScheme == .dark ? 0 : 6,
            shadowOffset: colorScheme == .dark ? 0 : 3
        )
    }
    
    private func textColor(for config: ButtonConfiguration) -> Color {
        // Для neutral всегда черный/белый
        if case .neutral = parameters.type {
            return colorScheme == .dark ? .white : .black
        }
        
        // Для цветных определяем контраст
        let averageColor = config.gradientColors.first ?? .black
        return averageColor.isLight ? .black : .white
    }
}

// MARK: - Button Configuration (упрощенная)
struct ButtonConfiguration {
    let gradientColors: [Color]
    let strokeColor: Color
    let strokeWidth: CGFloat
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowOffset: CGFloat
}

// MARK: - Button Types (без изменений)
enum BeautifulButtonType {
    case primary, neutral, secondary, compact
    
    var height: CGFloat {
        switch self {
        case .primary, .neutral: return 56
        case .secondary: return 44
        case .compact: return 38
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .primary, .neutral: return 16
        case .secondary: return 12
        case .compact: return 10
        }
    }
}

// MARK: - Color Extensions
extension Color {
    var isLight: Bool {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        return luminance > 0.5
    }
}

// MARK: - View Extensions (чистые, без UITraitCollection!)
extension View {
    
    // MARK: - Neutral кнопки
    
    /// Нейтральная кнопка с дефолтными цветами
    func neutralButton(isEnabled: Bool = true) -> some View {
        let parameters = ButtonStyleParameters(
            type: .neutral(primaryColor: .white, secondaryColor: .black),
            isEnabled: isEnabled,
            styleType: .neutral
        )
        return self.buttonStyle(BeautifulButtonStyle(parameters: parameters))
    }
    
    /// Нейтральная кнопка с кастомными цветами
    func neutralButton(
        primaryColor: Color = .white,
        secondaryColor: Color = .black,
        isEnabled: Bool = true
    ) -> some View {
        let parameters = ButtonStyleParameters(
            type: .neutral(primaryColor: primaryColor, secondaryColor: secondaryColor),
            isEnabled: isEnabled,
            styleType: .neutral
        )
        return self.buttonStyle(BeautifulButtonStyle(parameters: parameters))
    }
    
    // MARK: - Цветные кнопки
    
    /// Цветная кнопка с цветом приложения
    func beautifulButton(
        isEnabled: Bool = true,
        style: BeautifulButtonType = .primary,
        opacity: Double = 1.0
    ) -> some View {
        let parameters = ButtonStyleParameters(
            type: .colored(habitColor: AppColorManager.shared.selectedColor, opacity: opacity),
            isEnabled: isEnabled,
            styleType: style
        )
        return self.buttonStyle(BeautifulButtonStyle(parameters: parameters))
    }
    
    /// Цветная кнопка с цветом привычки
    func beautifulButton(
        habit: Habit,
        isEnabled: Bool = true,
        style: BeautifulButtonType = .primary,
        opacity: Double = 1.0
    ) -> some View {
        let parameters = ButtonStyleParameters(
            type: .colored(habitColor: habit.iconColor, opacity: opacity),
            isEnabled: isEnabled,
            styleType: style
        )
        return self.buttonStyle(BeautifulButtonStyle(parameters: parameters))
    }
    
    /// Цветная кнопка с кастомным HabitIconColor
    func beautifulButton(
        habitColor: HabitIconColor,
        isEnabled: Bool = true,
        style: BeautifulButtonType = .primary,
        opacity: Double = 1.0
    ) -> some View {
        let parameters = ButtonStyleParameters(
            type: .colored(habitColor: habitColor, opacity: opacity),
            isEnabled: isEnabled,
            styleType: style
        )
        return self.buttonStyle(BeautifulButtonStyle(parameters: parameters))
    }
    
    // MARK: - Обратная совместимость
    
    /// Цветная кнопка с кастомным Color (legacy)
    func beautifulButton(
        color: Color,
        isEnabled: Bool = true,
        style: BeautifulButtonType = .primary
    ) -> some View {
        let parameters = ButtonStyleParameters(
            type: .legacy(color: color),
            isEnabled: isEnabled,
            styleType: style
        )
        return self.buttonStyle(BeautifulButtonStyle(parameters: parameters))
    }
}
