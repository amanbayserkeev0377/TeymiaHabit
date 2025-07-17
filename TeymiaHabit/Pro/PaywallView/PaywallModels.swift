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
    
    // ⭐ Full initializer (если нужны разные цвета)
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
            colors: [Color.cyan, Color.blue]
        ),
        ProFeature(
            icon: "chart.bar.fill",
            title: "paywall_detailed_statistics_title".localized,
            description: "paywall_detailed_statistics_description".localized,
            colors: [Color.mint, Color.green]
        ),
        ProFeature(
            icon: "bell.badge.fill",
            title: "paywall_multiple_reminders_title".localized,
            description: "paywall_multiple_reminders_description".localized,
            colors: [Color.pink, Color.red]
        ),
        ProFeature(
            icon: "photo.stack.fill",
            title: "paywall_premium_icons_title".localized,
            description: "paywall_premium_icons_description".localized,
            colors: [Color.purple, Color.indigo]
        ),
        ProFeature(
            icon: "paintbrush.pointed.fill",
            title: "paywall_custom_colors_icons_title".localized,
            description: "paywall_custom_colors_icons_description".localized,
            colors: [Color.pink, Color.purple]
        ),
        ProFeature(
            icon: "sparkles",
            title: "paywall_upcoming_features_title".localized,
            description: "paywall_upcoming_features_description".localized,
            colors: [Color.yellow, Color.orange]
        ),
        ProFeature(
            icon: "heart.fill",
            title: "paywall_support_creator_title".localized,
            description: "paywall_support_creator_description".localized,
            colors: [Color.orange, Color.red]
        )
    ]
}

// MARK: - Updated FeatureRow with Environment
struct FeatureRow: View {
    let feature: ProFeature
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: feature.colors(for: colorScheme),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            // Text content
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
