import SwiftUI

// MARK: - Button Style Parameters (без изменений)
struct ButtonStyleParameters {
    enum ButtonType {
        case neutral(primaryColor: Color, secondaryColor: Color)
        case colored(habitColor: HabitIconColor, lightOpacity: Double, darkOpacity: Double)
        case legacy(color: Color)
    }
    
    let type: ButtonType
    let isEnabled: Bool
    let styleType: BeautifulButtonType
}

// MARK: - Beautiful Button Style (ИСПРАВЛЕНА логика градиентов)
struct BeautifulButtonStyle: ButtonStyle {
    let parameters: ButtonStyleParameters
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(parameters: ButtonStyleParameters) {
        self.parameters = parameters
    }
    
    func makeBody(configuration: Configuration) -> some View {
        let config = createConfiguration()
        
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
    
    // MARK: - Configuration Creation
    
    private func createConfiguration() -> ButtonConfiguration {
        switch parameters.type {
        case .neutral(let primaryColor, let secondaryColor):
            return createNeutralConfiguration(primaryColor: primaryColor, secondaryColor: secondaryColor)
            
        case .colored(let habitColor, let lightOpacity, let darkOpacity):
            return createColoredConfiguration(habitColor: habitColor, lightOpacity: lightOpacity, darkOpacity: darkOpacity)
            
        case .legacy(let color):
            return createLegacyConfiguration(color: color)
        }
    }
    
    private func createNeutralConfiguration(primaryColor: Color, secondaryColor: Color) -> ButtonConfiguration {
        return ButtonConfiguration(
            gradientColors: colorScheme == .dark ? [
                secondaryColor,  // В темной теме: темный вверх (если secondaryColor темный)
                primaryColor     // светлый низ (если primaryColor светлый)
            ] : [
                primaryColor,    // В светлой теме: светлый вверх (если primaryColor светлый)
                secondaryColor   // темный низ (если secondaryColor темный)
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
    
    // ✅ ИСПРАВЛЕННАЯ primary логика - точно как в AppColorManager
    private func createColoredConfiguration(habitColor: HabitIconColor, lightOpacity: Double, darkOpacity: Double) -> ButtonConfiguration {
        if habitColor == .primary {
            // ✅ ТОЧНО ТАКАЯ ЖЕ логика как в AppColorManager.getVisualRingColors для primary!
            // visualTop = Color.secondary (серый), visualBottom = Color.primary (черный/белый)
            let lightColor = Color.secondary    // Серый (в роли "светлого")
            let darkColor = Color.primary       // Черный/белый (в роли "темного")
            
            return ButtonConfiguration(
                // ✅ Используем ту же инвертированную логику что и для колец
                gradientColors: colorScheme == .dark ? [
                    lightColor.opacity(lightOpacity),   // темная тема: серый вверх
                    darkColor.opacity(darkOpacity),     // белый низ
                ] : [
                    lightColor.opacity(lightOpacity),   // светлая тема: серый вверх
                    darkColor.opacity(darkOpacity),     // черный низ
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
        } else {
            // ✅ ИСПРАВЛЕННАЯ логика для остальных цветов
            return ButtonConfiguration(
                gradientColors: colorScheme == .dark ? [
                    habitColor.darkColor.opacity(darkOpacity),    // темная тема: темный → светлый
                    habitColor.lightColor.opacity(lightOpacity),
                ] : [
                    habitColor.lightColor.opacity(lightOpacity),  // светлая тема: светлый → темный
                    habitColor.darkColor.opacity(darkOpacity),
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
            gradientColors: [color.opacity(0.5), color.opacity(0.8)], // оставляем как есть для legacy
            strokeColor: colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.12),
            strokeWidth: 0.7,
            shadowColor: colorScheme == .dark ? .clear : Color.black.opacity(0.1),
            shadowRadius: colorScheme == .dark ? 0 : 6,
            shadowOffset: colorScheme == .dark ? 0 : 3
        )
    }
    
    // ✅ ИСПРАВЛЕННАЯ логика textColor
    private func textColor(for config: ButtonConfiguration) -> Color {
        // Для neutral всегда черный/белый
        if case .neutral = parameters.type {
            return colorScheme == .dark ? .white : .black
        }
        
        // ✅ ИСПРАВЛЕННАЯ ЛОГИКА для primary цвета
        if case .colored(let habitColor, _, _) = parameters.type, habitColor == .primary {
            // Кнопка: светлая тема (серый→черный), темная тема (серый→белый)
            // Текст должен быть контрастным к основному цвету кнопки
            return colorScheme == .dark ? .black : .white  // инвертируем: темная тема = черный текст, светлая тема = белый текст
        }
        
        // ✅ УЛУЧШЕННАЯ ЛОГИКА: используем средний цвет градиента для лучшего контраста
        let averageColor = blendColors(config.gradientColors)
        return averageColor.bestContrastingTextColor
    }
    
    // ✅ НОВАЯ функция смешивания цветов для лучшего контраста
    private func blendColors(_ colors: [Color]) -> Color {
        guard !colors.isEmpty else { return .black }
        
        var totalRed: CGFloat = 0
        var totalGreen: CGFloat = 0
        var totalBlue: CGFloat = 0
        
        for color in colors {
            let uiColor = UIColor(color)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            totalRed += r
            totalGreen += g
            totalBlue += b
        }
        
        let count = CGFloat(colors.count)
        return Color(red: totalRed/count, green: totalGreen/count, blue: totalBlue/count)
    }
}

// MARK: - Button Configuration (без изменений)
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

// MARK: - Улучшенное расширение Color для лучшего accessibility
extension Color {
    
    /// Improved luminance calculation using sRGB gamma correction (WCAG 2.1 standard)
    var luminance: Double {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Apply sRGB gamma correction for better accuracy
        func gammaCorrect(_ component: CGFloat) -> Double {
            let c = Double(component)
            return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        
        let r = gammaCorrect(red)
        let g = gammaCorrect(green)
        let b = gammaCorrect(blue)
        
        // WCAG 2.1 relative luminance formula
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
    
    /// Better threshold for accessibility (WCAG AA compliance)
    var isLight: Bool {
        // БЫЛО: luminance > 0.5 (простое пороговое значение)
        // СТАЛО: luminance > 0.179 (оптимизировано для WCAG contrast ratio 4.5:1)
        return luminance > 0.179
    }
    
    /// Calculate contrast ratio with another color (WCAG 2.1 standard)
    func contrastRatio(with color: Color) -> Double {
        let l1 = max(self.luminance, color.luminance)
        let l2 = min(self.luminance, color.luminance)
        return (l1 + 0.05) / (l2 + 0.05)
    }
    
    /// Get best contrasting text color with guaranteed WCAG AA compliance
    var bestContrastingTextColor: Color {
        let whiteContrast = self.contrastRatio(with: .white)
        let blackContrast = self.contrastRatio(with: .black)
        
        // WCAG AA требует минимум 4.5:1 для нормального текста
        // WCAG AAA требует минимум 7:1 для лучшего accessibility
        
        if whiteContrast >= blackContrast {
            return .white
        } else {
            return .black
        }
    }
    
    /// Check if text color provides sufficient contrast (WCAG AA: 4.5:1)
    func hasGoodContrast(with textColor: Color) -> Bool {
        return self.contrastRatio(with: textColor) >= 4.5
    }
    
    /// Check if text color provides excellent contrast (WCAG AAA: 7:1)
    func hasExcellentContrast(with textColor: Color) -> Bool {
        return self.contrastRatio(with: textColor) >= 7.0
    }
}

// MARK: - View Extensions (обновленные)
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
    
    // MARK: - Цветные кнопки (НОВЫЕ с раздельной прозрачностью)
    
    /// Цветная кнопка с цветом приложения и раздельной прозрачностью
    func beautifulButton(
        isEnabled: Bool = true,
        style: BeautifulButtonType = .primary,
        lightOpacity: Double = 1.0,
        darkOpacity: Double = 1.0
    ) -> some View {
        let parameters = ButtonStyleParameters(
            type: .colored(habitColor: AppColorManager.shared.selectedColor, lightOpacity: lightOpacity, darkOpacity: darkOpacity),
            isEnabled: isEnabled,
            styleType: style
        )
        return self.buttonStyle(BeautifulButtonStyle(parameters: parameters))
    }
    
    /// Цветная кнопка с цветом привычки и раздельной прозрачностью
    func beautifulButton(
        habit: Habit,
        isEnabled: Bool = true,
        style: BeautifulButtonType = .primary,
        lightOpacity: Double = 1.0,
        darkOpacity: Double = 1.0
    ) -> some View {
        let parameters = ButtonStyleParameters(
            type: .colored(habitColor: habit.iconColor, lightOpacity: lightOpacity, darkOpacity: darkOpacity),
            isEnabled: isEnabled,
            styleType: style
        )
        return self.buttonStyle(BeautifulButtonStyle(parameters: parameters))
    }
    
    /// Цветная кнопка с кастомным HabitIconColor и раздельной прозрачностью
    func beautifulButton(
        habitColor: HabitIconColor,
        isEnabled: Bool = true,
        style: BeautifulButtonType = .primary,
        lightOpacity: Double = 1.0,
        darkOpacity: Double = 1.0
    ) -> some View {
        let parameters = ButtonStyleParameters(
            type: .colored(habitColor: habitColor, lightOpacity: lightOpacity, darkOpacity: darkOpacity),
            isEnabled: isEnabled,
            styleType: style
        )
        return self.buttonStyle(BeautifulButtonStyle(parameters: parameters))
    }
    
    // MARK: - Обратная совместимость (старый API с единой opacity)
    
    /// Цветная кнопка с цветом приложения (старый API)
    func beautifulButton(
        isEnabled: Bool = true,
        style: BeautifulButtonType = .primary,
        opacity: Double = 1.0
    ) -> some View {
        return beautifulButton(
            isEnabled: isEnabled,
            style: style,
            lightOpacity: opacity,
            darkOpacity: opacity
        )
    }
    
    /// Цветная кнопка с цветом привычки (старый API)
    func beautifulButton(
        habit: Habit,
        isEnabled: Bool = true,
        style: BeautifulButtonType = .primary,
        opacity: Double = 1.0
    ) -> some View {
        return beautifulButton(
            habit: habit,
            isEnabled: isEnabled,
            style: style,
            lightOpacity: opacity,
            darkOpacity: opacity
        )
    }
    
    /// Цветная кнопка с кастомным HabitIconColor (старый API)
    func beautifulButton(
        habitColor: HabitIconColor,
        isEnabled: Bool = true,
        style: BeautifulButtonType = .primary,
        opacity: Double = 1.0
    ) -> some View {
        return beautifulButton(
            habitColor: habitColor,
            isEnabled: isEnabled,
            style: style,
            lightOpacity: opacity,
            darkOpacity: opacity
        )
    }
    
    // MARK: - Legacy поддержка (с обычным Color)
    
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
