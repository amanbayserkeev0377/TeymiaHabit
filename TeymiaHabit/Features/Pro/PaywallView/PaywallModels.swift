import SwiftUI

// MARK: - Pro Feature Model

struct ProFeature {
    let id = UUID()
    let icon: String
    let title: LocalizedStringResource
    var description: LocalizedStringResource? = nil
    
    
    static let allFeatures: [ProFeature] = [
        ProFeature(
            icon: "infinity",
            title: "paywall_unlimited_habits_title",
            description: "paywall_unlimited_habits_description"
        ),
        ProFeature(
            icon: "bell",
            title: "paywall_multiple_reminders_title",
            description: "paywall_multiple_reminders_description"
        ),
        ProFeature(
            icon: "speaker.wave.2",
            title: "paywall_sounds_title",
            description: "paywall_sounds_description"
        ),
        ProFeature(
            icon: "document",
            title: "paywall_export_title"
        ),
        ProFeature(
            icon: "app.specular",
            title: "paywall_app_icons_title"
        ),
        ProFeature(
            icon: "sparkles",
            title: "paywall_access_new_features_title"
        )
    ]
}

// MARK: - FeatureRow

struct FeatureRow: View {
    let feature: ProFeature
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .frame(width: 40, height: 40)
                .foregroundStyle(.white.gradient)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.1))
                )
                
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.gradient)
                
                if let description = feature.description {
                    Text(description)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(2)
                }
                   
            }
            
            Spacer()
        }
    }
}
