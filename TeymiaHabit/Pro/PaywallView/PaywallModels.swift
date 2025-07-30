import SwiftUI

// MARK: - Pro Feature Model

struct ProFeature {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let lightColors: [Color]
    let darkColors: [Color]
    
    func colors(for colorScheme: ColorScheme) -> [Color] {
        return colorScheme == .dark ? darkColors : lightColors
    }
    
    init(icon: String, title: String, description: String, colors: [Color]) {
        self.icon = icon
        self.title = title
        self.description = description
        self.lightColors = colors
        self.darkColors = colors.reversed()
    }

    init(icon: String, title: String, description: String, lightColors: [Color], darkColors: [Color]) {
        self.icon = icon
        self.title = title
        self.description = description
        self.lightColors = lightColors
        self.darkColors = darkColors
    }
    
    static let allFeatures: [ProFeature] = [
        ProFeature(
            icon: "infinity",
            title: "paywall_unlimited_habits_title".localized,
            description: "paywall_unlimited_habits_description".localized,
            colors: [Color(#colorLiteral(red: 0.5725490196, green: 0.937254902, blue: 0.9921568627, alpha: 1)), Color(#colorLiteral(red: 0.3058823529, green: 0.3960784314, blue: 1, alpha: 1))]
        ),
        ProFeature(
            icon: "chart.bar.fill",
            title: "paywall_detailed_statistics_title".localized,
            description: "paywall_detailed_statistics_description".localized,
            colors: [Color(#colorLiteral(red: 0.2196078431, green: 0.937254902, blue: 0.4901960784, alpha: 1)), Color(#colorLiteral(red: 0.06666666667, green: 0.6, blue: 0.5568627451, alpha: 1))]
        ),
        ProFeature(
            icon: "bell.badge.fill",
            title: "paywall_multiple_reminders_title".localized,
            description: "paywall_multiple_reminders_description".localized,
            colors: [Color(#colorLiteral(red: 1, green: 0.3725490196, blue: 0.4274509804, alpha: 1)), Color(#colorLiteral(red: 0.8, green: 0.1, blue: 0.1, alpha: 1))]
        ),
        ProFeature(
            icon: "speaker.wave.2",
            title: "paywall_completion_sounds_title".localized,
            description: "paywall_completion_sounds_description".localized,
            colors: [Color(#colorLiteral(red: 1, green: 0.3725490196, blue: 0.4274509804, alpha: 1)), Color(#colorLiteral(red: 0.8, green: 0.1, blue: 0.1, alpha: 1))]
        ),
        ProFeature(
            icon: "photo.stack.fill",
            title: "paywall_premium_icons_title".localized,
            description: "paywall_premium_icons_description".localized,
            colors: [Color(#colorLiteral(red: 0.7803921569, green: 0.3803921569, blue: 0.7568627451, alpha: 1)), Color(#colorLiteral(red: 0.4225856662, green: 0.5768597722, blue: 0.9980003238, alpha: 1))]
        ),
        ProFeature(
            icon: "paintbrush.pointed.fill",
            title: "paywall_custom_colors_icons_title".localized,
            description: "paywall_custom_colors_icons_description".localized,
            colors: [Color.purple, Color.pink]
        ),
        ProFeature(
            icon: "sparkles",
            title: "paywall_upcoming_features_title".localized,
            description: "paywall_upcoming_features_description".localized,
            colors: [Color(#colorLiteral(red: 1, green: 0.6, blue: 0.4, alpha: 1)), Color(#colorLiteral(red: 1, green: 0.368627451, blue: 0.3843137255, alpha: 1))]
        ),
        ProFeature(
            icon: "heart.fill",
            title: "paywall_support_creator_title".localized,
            description: "paywall_support_creator_description".localized,
            colors: [Color(#colorLiteral(red: 1, green: 0.7647058824, blue: 0.4431372549, alpha: 1)), Color(#colorLiteral(red: 1, green: 0.3725490196, blue: 0.4274509804, alpha: 1))]
        )
    ]
}

// MARK: - FeatureRow

struct FeatureRow: View {
    let feature: ProFeature
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark ? [
                                Color(#colorLiteral(red: 0.08235294118, green: 0.08235294118, blue: 0.08235294118, alpha: 1)),
                                Color(#colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1))
                            ] : [
                                feature.lightColors[0],
                                feature.lightColors[1]
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(
                                Color.gray.opacity(0.4),
                                lineWidth: 0.3
                            )
                    )
                
                Image(systemName: feature.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        colorScheme == .dark ?
                        LinearGradient(
                            colors: [
                                feature.lightColors[0],
                                feature.lightColors[1]
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ) :
                        LinearGradient(colors: [.white, .white], startPoint: .top, endPoint: .bottom)
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
