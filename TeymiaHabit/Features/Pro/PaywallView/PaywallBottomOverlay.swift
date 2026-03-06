import SwiftUI
import RevenueCat

struct PaywallBottomOverlay: View {
    let offerings: Offerings
    @Binding var selectedPackage: Package?
    let isPurchasing: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ForEach(sortedPackages, id: \.identifier) { package in
                    PricingCard(
                        package: package,
                        offerings: offerings,
                        isSelected: selectedPackage?.identifier == package.identifier
                    ) {
                        selectedPackage = package
                        HapticManager.shared.playSelection()
                    }
                }
            }
            PurchaseButton(
                selectedPackage: selectedPackage,
                offerings: offerings,
                isPurchasing: isPurchasing,
                onTap: onPurchase
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
    
    private var sortedPackages: [Package] {
        guard let currentOffering = offerings.current else { return [] }
        
        return currentOffering.availablePackages.sorted { first, second in
            if first.packageType == .monthly && second.packageType != .monthly {
                return true
            }
            if second.packageType == .monthly && first.packageType != .monthly {
                return false
            }
            
            if first.packageType == .annual && second.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase {
                return true
            }
            if second.packageType == .annual && first.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase {
                return false
            }
            
            if first.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase {
                return false
            }
            if second.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase {
                return true
            }
            
            return false
        }
    }
}

struct PricingCard: View {
    let package: Package
    let offerings: Offerings
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var hasAppeared = false
    
    private var cardType: PricingCardType {
        if package.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase {
            return .lifetime
        } else if package.packageType == .annual {
            return .yearly
        } else {
            return .monthly
        }
    }
    
    private var cardIcon: String {
        switch cardType {
        case .monthly: return "calendar.badge.checkmark"
        case .yearly: return "gift"
        case .lifetime: return "infinity"
        }
    }
    
    private var cardTitle: LocalizedStringResource {
        switch cardType {
        case .monthly: return "paywall_monthly_plan"
        case .yearly: return "paywall_yearly_plan"
        case .lifetime: return "paywall_lifetime_plan"
        }
    }
    
    private var cardPrice: String {
        return package.storeProduct.localizedPriceString
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: cardIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? Color.black.gradient : Color.white.gradient)
                
                Text(cardTitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? Color.black.gradient : Color.white.gradient)
                    .multilineTextAlignment(.center)
                
                Text(cardPrice)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(isSelected ? Color.black.gradient : Color.white.gradient)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .padding(.horizontal, 8)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(.white.gradient)
                    } else {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(.clear)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                hasAppeared = true
            }
        }
    }
}

struct PurchaseButton: View {
    let selectedPackage: Package?
    let offerings: Offerings
    let isPurchasing: Bool
    let onTap: () -> Void
    
    private var buttonText: LocalizedStringKey {
        if isPurchasing {
            return "paywall_processing_button"
        }
        
        guard let selectedPackage = selectedPackage else {
            return "paywall_continue"
        }
        
        if selectedPackage.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase {
            return "paywall_lifetime_cta"
        } else if selectedPackage.packageType == .annual {
            return getYearlyButtonText()
        } else {
            return "paywall_subscribe_cta"
        }
    }
    
    private func getYearlyButtonText() -> LocalizedStringKey {
        guard let selectedPackage = selectedPackage else {
            return "paywall_7_days_free_trial_cta"
        }
        
        let monthlyPrice = selectedPackage.storeProduct.price / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = selectedPackage.storeProduct.priceFormatter?.locale
        let isSmallAmount = (monthlyPrice as NSDecimalNumber).doubleValue < 10
        formatter.maximumFractionDigits = isSmallAmount ? 1 : 0
        
        let priceString = formatter.string(from: monthlyPrice as NSDecimalNumber) ?? ""
        
        return "paywall_start_trial_monthly \(priceString)"
    }
    
    private func formatPrice(_ price: Double) -> String {
        if price < 1 { return String(format: "%.2f", price) }
        if price < 10 { return String(format: "%.1f", price) }
        return String(format: "%.0f", price)
    }
    
    private func extractCurrencySymbol(from priceString: String) -> String {
        if priceString.contains("$") { return "$" }
        if priceString.contains("€") { return "€" }
        if priceString.contains("£") { return "£" }
        if priceString.contains("₽") { return "₽" }
        if priceString.contains("¥") { return "¥" }
        if priceString.contains("₹") { return "₹" }
        if priceString.contains("₩") { return "₩" }
        
        if let currencyChar = priceString.first(where: { !$0.isNumber && !$0.isWhitespace && $0 != "." && $0 != "," }) {
            return String(currencyChar)
        }
        
        return "$"
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if isPurchasing {
                    ProgressView()
                        .scaleEffect(0.9)
                        .tint(.black)
                }
                
                Text(buttonText)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black.gradient)
                    .shimmer(.init(blur: 7, highlightOpacity: 0.8, speed: 2))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Capsule().fill(.white.gradient))
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .disabled(selectedPackage == nil || isPurchasing)
        .opacity(selectedPackage == nil || isPurchasing ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isPurchasing)
    }
}

// MARK: - Helper Types

enum PricingCardType {
    case monthly, yearly, lifetime
}
