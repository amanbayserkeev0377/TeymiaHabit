import SwiftUI

struct ProGradientColors {
    static let colors = [
        Color(#colorLiteral(red: 0.4235294118, green: 0.5764705882, blue: 0.9960784314, alpha: 1)),
        Color(#colorLiteral(red: 0.7803921569, green: 0.3803921569, blue: 0.7568627451, alpha: 1))
    ]
    
    // MARK: - Gradients
    static func gradient(startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing) -> LinearGradient {
        LinearGradient(
            colors: colors,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    static let proGradient = LinearGradient(
        colors: colors,
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let proAccentColor = Color(#colorLiteral(red: 0.4925274849, green: 0.5225450397, blue: 0.9995061755, alpha: 1))
}

// MARK: - View Extensions
extension View {
    func withProGradient(startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing) -> some View {
        background(ProGradientColors.gradient(startPoint: startPoint, endPoint: endPoint))
    }
    
    func proGradientForeground(startPoint: UnitPoint = .leading, endPoint: UnitPoint = .trailing) -> some View {
        foregroundStyle(ProGradientColors.gradient(startPoint: startPoint, endPoint: endPoint))
    }
}
