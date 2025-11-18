import SwiftUI

// MARK: - Pro Feature Model

struct ProFeature {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: AnyGradient
    
    init(icon: String, title: String, description: String, color: AnyGradient) {
        self.icon = icon
        self.title = title
        self.description = description
        self.color = color
    }
    
    static let allFeatures: [ProFeature] = [
        ProFeature(
            icon: "infinity",
            title: "paywall_unlimited_habits_title".localized,
            description: "paywall_unlimited_habits_description".localized,
            color: Color.blue.gradient
        ),
        ProFeature(
            icon: "stats.fill",
            title: "paywall_detailed_statistics_title".localized,
            description: "paywall_detailed_statistics_description".localized,
            color: Color.green.gradient
        ),
        ProFeature(
            icon: "bell",
            title: "paywall_multiple_reminders_title".localized,
            description: "paywall_multiple_reminders_description".localized,
            color: Color.red.gradient
        ),
        ProFeature(
            icon: "sounds",
            title: "paywall_completion_sounds_title".localized,
            description: "paywall_completion_sounds_description".localized,
            color: Color.red.gradient
        ),
        ProFeature(
            icon: "paintbrush",
            title: "paywall_custom_colors_icons_title".localized,
            description: "paywall_custom_colors_icons_description".localized,
            color: Color.purple.gradient
        ),
        ProFeature(
            icon: "export",
            title: "paywall_export_title".localized,
            description: "paywall_export_description".localized,
            color: Color.gray.gradient
        ),
        ProFeature(
            icon: "heart",
            title: "paywall_support_creator_title".localized,
            description: "paywall_support_creator_description".localized,
            color: Color.orange.gradient
        )
    ]
}

// MARK: - FeatureRow

struct FeatureRow: View {
    let feature: ProFeature
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            
            Image(feature.icon)
                .resizable()
                .frame(width: 28, height: 28)
                .foregroundStyle(feature.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                    .fontDesign(.rounded)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(feature.description)
                    .font(.subheadline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
