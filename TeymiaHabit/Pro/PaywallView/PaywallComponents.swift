import SwiftUI
import RevenueCat

// MARK: - Paywall Header Section
struct PaywallHeaderSection: View {
    var body: some View {
        VStack(spacing: 20) {
            // Laurels with centered text
            HStack {
                Image(systemName: "laurel.leading")
                    .font(.system(size: 62))
                    .foregroundStyle(ProGradientColors.proGradient)
                Spacer()
                
                Text("Teymia Habit Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(ProGradientColors.proGradient)
                
                Spacer()
                
                Image(systemName: "laurel.trailing")
                    .font(.system(size: 62))
                    .foregroundStyle(ProGradientColors.proGradient)
            }
        }
    }
}

// MARK: - Paywall Features Section
struct PaywallFeaturesSection: View {
    var body: some View {
        VStack(spacing: 20) {
            ForEach(ProFeature.allFeatures, id: \.id) { feature in
                FeatureRow(feature: feature) // ⭐ Убираем colorScheme
            }
        }
    }
}
