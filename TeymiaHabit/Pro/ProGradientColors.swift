import SwiftUI

// MARK: - Pro Gradient Colors
struct ProGradientColors {
    
    // Основная цветовая пара для всех градиентов
    static let colors = [
        Color(#colorLiteral(red: 0.4225856662, green: 0.5768597722, blue: 0.9980003238, alpha: 1)), // Синий
        Color(#colorLiteral(red: 0.7803921569, green: 0.3803921569, blue: 0.7568627451, alpha: 1))  // Розоватый
    ]
    
    // MARK: - Настраиваемые градиенты
    
    /// Основной Pro градиент с настраиваемыми точками
    static func gradient(startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing) -> LinearGradient {
        return LinearGradient(
            colors: colors,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    // MARK: - Готовые варианты для частых случаев
    
    static let proGradient = LinearGradient(
        colors: colors,
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Для текста/иконок - средний цвет между синим и розовым = фиолетовый
    static let proAccentColor = Color(#colorLiteral(red: 0.4925274849, green: 0.5225450397, blue: 0.9995061755, alpha: 1))
    
    // MARK: - Алиасы для обратной совместимости
    static let gradientColors = colors
}

// MARK: - View Extension для удобства
extension View {
    func withProGradient(startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing) -> some View {
        self.background(ProGradientColors.gradient(startPoint: startPoint, endPoint: endPoint))
    }
    
    func proGradientForeground(startPoint: UnitPoint = .leading, endPoint: UnitPoint = .trailing) -> some View {
        self.foregroundStyle(ProGradientColors.gradient(startPoint: startPoint, endPoint: endPoint))
    }
}
