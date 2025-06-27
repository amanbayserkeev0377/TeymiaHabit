import SwiftUI

// MARK: - Pro Gradient Colors
struct ProGradientColors {
    
    // Основные цвета градиента
    static let gradientColors = [
        Color(#colorLiteral(red: 0.4225856662, green: 0.5768597722, blue: 0.9980003238, alpha: 1)),
        Color(#colorLiteral(red: 0.7803921569, green: 0.3803921569, blue: 0.7568627451, alpha: 1))
    ]
    
    static let simpleGradientColors = [
        Color(#colorLiteral(red: 0.4225856662, green: 0.5768597722, blue: 0.9980003238, alpha: 1)),
        Color(#colorLiteral(red: 0.7803002596, green: 0.3821231425, blue: 0.7560456395, alpha: 1)),
    ]
    
    // MARK: - Настраиваемые градиенты
    
    /// Основной Pro градиент с настраиваемыми точками
    static func proGradient(startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing) -> LinearGradient {
        return LinearGradient(
            colors: gradientColors,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /// Упрощенный Pro градиент с настраиваемыми точками
    static func proGradientSimple(startPoint: UnitPoint = .leading, endPoint: UnitPoint = .trailing) -> LinearGradient {
        return LinearGradient(
            colors: simpleGradientColors,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    // MARK: - Готовые варианты (для обратной совместимости)
    
    static let proGradient = LinearGradient(
        colors: gradientColors,
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let proGradientSimple = LinearGradient(
        colors: simpleGradientColors,
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Для текста/иконок - берем средний цвет
    static let proAccentColor = Color(#colorLiteral(red: 0.4925274849, green: 0.5225450397, blue: 0.9995061755, alpha: 1))
}

// MARK: - View Extension для удобства
extension View {
    func withProGradient(startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing) -> some View {
        self.background(ProGradientColors.proGradient(startPoint: startPoint, endPoint: endPoint))
    }
    
    func withProGradientSimple(startPoint: UnitPoint = .leading, endPoint: UnitPoint = .trailing) -> some View {
        self.background(ProGradientColors.proGradientSimple(startPoint: startPoint, endPoint: endPoint))
    }
    
    func proGradientForeground(startPoint: UnitPoint = .leading, endPoint: UnitPoint = .trailing) -> some View {
        self.foregroundStyle(ProGradientColors.proGradientSimple(startPoint: startPoint, endPoint: endPoint))
    }
}
