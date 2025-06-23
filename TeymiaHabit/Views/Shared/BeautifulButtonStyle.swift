import SwiftUI

// MARK: - Button Configuration (обновленный под чистые цвета)
struct ButtonConfiguration {
    let gradientColors: [Color]
    let strokeColor: Color
    let strokeWidth: CGFloat
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowOffset: CGFloat
    
    // Конфигурация для нейтральных кнопок (WhatsNew, etc)
    static func neutral(
        colorScheme: ColorScheme,
        primaryColor: Color = .white,
        secondaryColor: Color = .black
    ) -> ButtonConfiguration {
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
    
    // Конфигурация для цветных кнопок (с HabitIconColor)
    static func colored(
        habitColor: HabitIconColor,
        colorScheme: ColorScheme,
        opacity: Double = 1.0
    ) -> ButtonConfiguration {
        return ButtonConfiguration(
            gradientColors: habitColor.gradientColors(
                lightOpacity: opacity,
                darkOpacity: opacity
            ),
            strokeColor: colorScheme == .dark
                ? Color.white.opacity(0.15)
                : Color.black.opacity(0.12),  // Нейтральный stroke для объема
            strokeWidth: 0.7,
            shadowColor: colorScheme == .dark
                ? .clear
                : Color.black.opacity(0.1),
            shadowRadius: colorScheme == .dark ? 0 : 6,
            shadowOffset: colorScheme == .dark ? 0 : 3
        )
    }
    
    // Кастомная конфигурация (как было)
    static func custom(
        gradientColors: [Color],
        strokeColor: Color,
        strokeWidth: CGFloat = 1.0,
        shadowColor: Color = .clear,
        shadowRadius: CGFloat = 0,
        shadowOffset: CGFloat = 0
    ) -> ButtonConfiguration {
        return ButtonConfiguration(
            gradientColors: gradientColors,
            strokeColor: strokeColor,
            strokeWidth: strokeWidth,
            shadowColor: shadowColor,
            shadowRadius: shadowRadius,
            shadowOffset: shadowOffset
        )
    }
}

// MARK: - Beautiful Button Style (обновленный)
struct BeautifulButtonStyle: ButtonStyle {
    let configuration: ButtonConfiguration
    let isEnabled: Bool
    let style: BeautifulButtonType
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(configuration: ButtonConfiguration, isEnabled: Bool = true, style: BeautifulButtonType = .primary) {
        self.configuration = configuration
        self.isEnabled = isEnabled
        self.style = style
    }
    
    // Инициализатор для HabitIconColor
    init(habitColor: HabitIconColor, isEnabled: Bool = true, style: BeautifulButtonType = .primary, opacity: Double = 1.0) {
        self.isEnabled = isEnabled
        self.style = style
        
        let colorScheme = UITraitCollection.current.userInterfaceStyle == .dark ? ColorScheme.dark : .light
        
        switch style {
        case .neutral:
            // Для neutral используем дефолтные цвета
            self.configuration = .neutral(colorScheme: colorScheme)
        default:
            // Для цветных используем HabitIconColor
            self.configuration = .colored(habitColor: habitColor, colorScheme: colorScheme, opacity: opacity)
        }
    }
    
    // Старый инициализатор для обратной совместимости
    init(color: Color, isEnabled: Bool = true, style: BeautifulButtonType = .primary) {
        self.isEnabled = isEnabled
        self.style = style
        
        let colorScheme = UITraitCollection.current.userInterfaceStyle == .dark ? ColorScheme.dark : .light
        
        switch style {
        case .neutral:
            self.configuration = .neutral(colorScheme: colorScheme)
        default:
            // Эмулируем старое поведение через кастомную конфигурацию
            self.configuration = .custom(
                gradientColors: [color.opacity(0.5), color.opacity(0.8)],
                strokeColor: colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.12),
                strokeWidth: 0.7,
                shadowColor: colorScheme == .dark ? .clear : Color.black.opacity(0.1),
                shadowRadius: colorScheme == .dark ? 0 : 6,
                shadowOffset: colorScheme == .dark ? 0 : 3
            )
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(isEnabled ? textColor : .secondary)
            .frame(maxWidth: .infinity)
            .frame(height: style.height)
            .background(
                LinearGradient(
                    colors: isEnabled ? self.configuration.gradientColors : [Color.gray.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .stroke(
                        isEnabled ? self.configuration.strokeColor : Color.gray.opacity(0.3),
                        lineWidth: self.configuration.strokeWidth
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
            .shadow(
                color: isEnabled ? self.configuration.shadowColor : .clear,
                radius: isEnabled ? self.configuration.shadowRadius : 0,
                x: 0,
                y: isEnabled ? self.configuration.shadowOffset : 0
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .scaleEffect(isEnabled ? 1.0 : 0.95)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
            .disabled(!isEnabled)
    }
    
    private var textColor: Color {
        // Для neutral всегда черный/белый
        if case .neutral = style {
            return colorScheme == .dark ? .white : .black
        }
        
        // Для цветных определяем контраст
        let averageColor = configuration.gradientColors.first ?? .black
        return averageColor.isLight ? .black : .white
    }
}

// MARK: - Button Types (без изменений)
enum BeautifulButtonType {
    case primary      // Цветные основные кнопки
    case neutral      // Нейтральные кнопки
    case secondary    // Второстепенные кнопки
    case compact      // Компактные кнопки
    
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

// MARK: - Color Extensions (без изменений)
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

// MARK: - View Extensions (обновленные под HabitIconColor)
extension View {
    /// Нейтральная кнопка с дефолтными цветами
    func neutralButton(isEnabled: Bool = true) -> some View {
        self.buttonStyle(BeautifulButtonStyle(
            habitColor: .primary, // Не важно для neutral
            isEnabled: isEnabled,
            style: .neutral
        ))
    }
    
    /// Нейтральная кнопка с кастомными цветами (адаптивный градиент)
    func neutralButton(
        primaryColor: Color = .white,
        secondaryColor: Color = .black,
        isEnabled: Bool = true
    ) -> some View {
        let colorScheme = UITraitCollection.current.userInterfaceStyle == .dark ? ColorScheme.dark : .light
        let config = ButtonConfiguration.neutral(
            colorScheme: colorScheme,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor
        )
        
        return self.buttonStyle(BeautifulButtonStyle(
            configuration: config,
            isEnabled: isEnabled,
            style: .neutral
        ))
    }
    
    /// Цветная кнопка с цветом приложения (через HabitIconColor)
    func beautifulButton(isEnabled: Bool = true, style: BeautifulButtonType = .primary, opacity: Double = 1.0) -> some View {
        self.buttonStyle(BeautifulButtonStyle(
            habitColor: AppColorManager.shared.selectedColor,
            isEnabled: isEnabled,
            style: style,
            opacity: opacity
        ))
    }
    
    /// Цветная кнопка с цветом привычки (через HabitIconColor)
    func beautifulButton(habit: Habit, isEnabled: Bool = true, style: BeautifulButtonType = .primary, opacity: Double = 1.0) -> some View {
        self.buttonStyle(BeautifulButtonStyle(
            habitColor: habit.iconColor,
            isEnabled: isEnabled,
            style: style,
            opacity: opacity
        ))
    }
    
    /// Цветная кнопка с кастомным HabitIconColor
    func beautifulButton(habitColor: HabitIconColor, isEnabled: Bool = true, style: BeautifulButtonType = .primary, opacity: Double = 1.0) -> some View {
        self.buttonStyle(BeautifulButtonStyle(
            habitColor: habitColor,
            isEnabled: isEnabled,
            style: style,
            opacity: opacity
        ))
    }
    
    /// Цветная кнопка с кастомным Color (для обратной совместимости)
    func beautifulButton(color: Color, isEnabled: Bool = true, style: BeautifulButtonType = .primary) -> some View {
        self.buttonStyle(BeautifulButtonStyle(
            color: color,
            isEnabled: isEnabled,
            style: style
        ))
    }
    
    /// Кнопка с полностью кастомной конфигурацией
    func customButton(
        gradientColors: [Color],
        strokeColor: Color,
        strokeWidth: CGFloat = 1.0,
        shadowColor: Color = .clear,
        shadowRadius: CGFloat = 0,
        shadowOffset: CGFloat = 0,
        isEnabled: Bool = true,
        style: BeautifulButtonType = .primary
    ) -> some View {
        let config = ButtonConfiguration.custom(
            gradientColors: gradientColors,
            strokeColor: strokeColor,
            strokeWidth: strokeWidth,
            shadowColor: shadowColor,
            shadowRadius: shadowRadius,
            shadowOffset: shadowOffset
        )
        
        return self.buttonStyle(BeautifulButtonStyle(
            configuration: config,
            isEnabled: isEnabled,
            style: style
        ))
    }
}
