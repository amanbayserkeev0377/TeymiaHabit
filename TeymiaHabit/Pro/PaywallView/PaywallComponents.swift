import SwiftUI
import RevenueCat

// MARK: - Paywall Background Gradient
struct PaywallBackgroundGradient: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark ? [
                // Темная тема - те же тона что в WhatsNew
                Color(#colorLiteral(red: 0.1215686275, green: 0.1294117647, blue: 0.1607843137, alpha: 1)), // Темно-серый с фиолетовым
                Color(#colorLiteral(red: 0.1568627451, green: 0.1647058824, blue: 0.2196078431, alpha: 1)), // Темно-синий
                Color(#colorLiteral(red: 0.1843137255, green: 0.1725490196, blue: 0.2588235294, alpha: 1))  // Темно-фиолетовый
            ] : [
                // Светлая тема - те же тона что в WhatsNew
                Color(#colorLiteral(red: 0.9098039216, green: 0.9176470588, blue: 0.9647058824, alpha: 1)), // Очень светлый лавандовый
                Color(#colorLiteral(red: 0.8235294118, green: 0.8470588235, blue: 0.9215686275, alpha: 1)), // Мягкий фиолетовый
                Color(#colorLiteral(red: 0.7450980392, green: 0.7803921569, blue: 0.8784313725, alpha: 1))  // Чуть темнее
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Paywall Header Section
struct PaywallHeaderSection: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            // Laurels with centered text
            HStack {
                Image(systemName: "laurel.leading")
                    .font(.system(size: 62))
                    .foregroundStyle(ProGradientColors.proGradientSimple)
                
                Spacer()
                
                Text("paywall_header_title".localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                Image(systemName: "laurel.trailing")
                    .font(.system(size: 62))
                    .foregroundStyle(ProGradientColors.proGradientSimple)
            }
        }
    }
}

// MARK: - Paywall Features Section
struct PaywallFeaturesSection: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            ForEach(ProFeature.allFeatures, id: \.id) { feature in
                FeatureRow(feature: feature, colorScheme: colorScheme)
            }
        }
    }
}

// MARK: - Paywall Footer Section
struct PaywallFooterSection: View {
    let colorScheme: ColorScheme
    let onRestorePurchases: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Restore button
            Button("paywall_restore_purchases_button".localized) {
                onRestorePurchases()
            }
            .font(.subheadline)
            .foregroundStyle(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7))
            
            // Regional pricing notice
            Text("paywall_regional_pricing_notice".localized)
                .font(.caption)
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding(.horizontal, 8)
            
            // Family Sharing button
            Button {
                if let url = URL(string: "https://www.apple.com/family-sharing/") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .font(.subheadline)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple, Color.blue, Color.green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("paywall_family_sharing_button".localized)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            
            // Legal text
            Text("paywall_legal_text".localized)
                .font(.caption)
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            
            // Terms and Privacy
            HStack(spacing: 30) {
                Button("Terms of Service") {
                    if let url = URL(string: "https://www.notion.so/Terms-of-Service-204d5178e65a80b89993e555ffd3511f") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption)
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                
                Button("Privacy Policy") {
                    if let url = URL(string: "https://www.notion.so/Privacy-Policy-1ffd5178e65a80d4b255fd5491fba4a8") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption)
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
            }
        }
    }
}

// MARK: - Fallback Loading View (for Apple reviewers)
struct PaywallFallbackView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Loading subscription options...")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            // Static information for Apple compliance
            VStack(spacing: 8) {
                Text("Monthly: $0.99/month")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Yearly: $5.99/year (7-day free trial)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Lifetime: $9.99 (one-time payment)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
        }
    }
}
