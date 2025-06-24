import SwiftUI
import RevenueCat

// MARK: - Regular Subscription Pricing Card
struct PricingCard: View {
    let package: Package
    let isSelected: Bool
    let offering: Offering
    let colorScheme: ColorScheme
    let onTap: () -> Void
    
    private var isMonthly: Bool {
        package.packageType == .monthly
    }
    
    private var isYearly: Bool {
        package.packageType == .annual
    }
    
    private var planName: String {
        isYearly ? "paywall_yearly_plan".localized : "paywall_monthly_plan".localized
    }
    
    private var priceText: String {
        let price = package.storeProduct.localizedPriceString
        return isYearly ? "\(price)/year" : "\(price)/month"
    }
    
    private var descriptionText: String {
        if isMonthly {
            return "paywall_monthly_description".localized
        } else {
            return "paywall_yearly_description".localized
        }
    }
    
    var body: some View {
        let cardBackground = colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.white.opacity(0.6)
        
        let strokeColor = isSelected
            ? ProGradientColors.proAccentColor
            : (colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.1))
        
        let strokeWidth: CGFloat = isSelected ? 2 : 1
        
        let shadowColor = isSelected
            ? ProGradientColors.proAccentColor.opacity(0.2)
            : Color.clear
        
        let shadowRadius: CGFloat = isSelected ? 8 : 0
        let shadowY: CGFloat = isSelected ? 4 : 0
        
        Button(action: {
            onTap()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(planName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                    
                    Text(descriptionText)
                        .font(.subheadline)
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(priceText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                    
                    if isYearly {
                        Text("paywall_free_trial_label".localized)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(ProGradientColors.proGradientSimple)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(strokeColor, lineWidth: strokeWidth)
            )
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Lifetime Pricing Card
struct LifetimePricingCard: View {
    let package: Package
    let isSelected: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void
    
    var body: some View {
        let cardBackground = colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.white.opacity(0.6)
        
        let strokeColor = isSelected
            ? Color.orange
            : (colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.1))
        
        let strokeWidth: CGFloat = isSelected ? 2 : 1
        
        let shadowColor = isSelected
            ? Color.orange.opacity(0.2)
            : Color.clear
        
        let shadowRadius: CGFloat = isSelected ? 8 : 0
        let shadowY: CGFloat = isSelected ? 4 : 0
        
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("paywall_lifetime_plan".localized)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                        
                        // "Best Value" badge
                        Text("paywall_best_value".localized)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.orange, Color.red],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    
                    Text("paywall_lifetime_description".localized)
                        .font(.subheadline)
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(package.storeProduct.localizedPriceString)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                    
                    Text("paywall_one_time_payment".localized)
                        .font(.caption2)
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(strokeColor, lineWidth: strokeWidth)
            )
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
