import SwiftUI

// MARK: - Pro Feature Model
struct ProFeature {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let colors: [Color]
    
    static let allFeatures: [ProFeature] = [
        ProFeature(
            icon: "infinity",
            title: "paywall_unlimited_habits_title".localized,
            description: "paywall_unlimited_habits_description".localized,
            colors: [Color.orange, Color.yellow]
        ),
        ProFeature(
            icon: "folder.fill",
            title: "paywall_habit_folders_title".localized,
            description: "paywall_habit_folders_description".localized,
            colors: [Color.blue, Color.cyan]
        ),
        ProFeature(
            icon: "paintbrush.pointed.fill",
            title: "paywall_custom_colors_icons_title".localized,
            description: "paywall_custom_colors_icons_description".localized,
            colors: [Color.purple, Color.pink]
        ),
        ProFeature(
            icon: "heart.fill",
            title: "paywall_support_creator_title".localized,
            description: "paywall_support_creator_description".localized,
            colors: [Color.red, Color.orange]
        )
    ]
}

// MARK: - Feature Row (UI component for displaying features)
struct FeatureRow: View {
    let feature: ProFeature
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: feature.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
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
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
