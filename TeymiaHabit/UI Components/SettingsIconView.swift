import SwiftUI

// MARK: - Settings Icon Modifier

private struct SettingsIconModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    let lightColors: [Color]
    let fontSize: CGFloat
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle(
                colorScheme == .dark ?
                LinearGradient(
                    colors: [
                        lightColors.first ?? .blue,
                        lightColors.last ?? .blue
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ) :
                LinearGradient(colors: [.white, .white], startPoint: .top, endPoint: .bottom)
            )
            .font(.system(size: fontSize, weight: .medium))
            .frame(width: 30, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark ? [
                                Color(#colorLiteral(red: 0.08235294118, green: 0.08235294118, blue: 0.08235294118, alpha: 1)),
                                Color(#colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1))
                            ] : [
                                lightColors.first ?? .blue,
                                lightColors.last ?? .blue
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(
                                Color.gray.opacity(0.4),
                                lineWidth: 0.4
                            )
                    )
            )
    }
}

// MARK: - Gradient Icon Modifier

private struct GradientIconModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    let gradientColors: [Color]
    let startPoint: UnitPoint
    let endPoint: UnitPoint
    let fontSize: CGFloat
    
    func body(content: Content) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    colorScheme == .dark ?
                    LinearGradient(
                        colors: [
                            Color(#colorLiteral(red: 0.08235294118, green: 0.08235294118, blue: 0.08235294118, alpha: 1)),
                            Color(#colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1))
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ) :
                    LinearGradient(colors: [.white, .white], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 29, height: 29)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(
                            Color.gray.opacity(0.4),
                            lineWidth: 0.4
                        )
                )
            
            content
                .font(.system(size: fontSize, weight: .medium))
                .foregroundStyle(.linearGradient(
                    colors: gradientColors,
                    startPoint: startPoint,
                    endPoint: endPoint
                ))
        }
    }
}

// MARK: - View Extensions

extension View {
    func withIOSSettingsIcon(
        lightColors: [Color],
        fontSize: CGFloat = 14
    ) -> some View {
        modifier(SettingsIconModifier(
            lightColors: lightColors,
            fontSize: fontSize
        ))
    }
    
    func withGradientIcon(
        colors: [Color],
        startPoint: UnitPoint = .top,
        endPoint: UnitPoint = .bottom,
        fontSize: CGFloat = 15
    ) -> some View {
        modifier(GradientIconModifier(
            gradientColors: colors,
            startPoint: startPoint,
            endPoint: endPoint,
            fontSize: fontSize
        ))
    }
}
