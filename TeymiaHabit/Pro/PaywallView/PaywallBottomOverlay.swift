import SwiftUI
import RevenueCat

// MARK: - Paywall Bottom Overlay
struct PaywallBottomOverlay: View {
    let offerings: Offerings
    @Binding var selectedPackage: Package?
    let isPurchasing: Bool
    let colorScheme: ColorScheme
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Pricing Cards
            HStack(spacing: 12) {
                ForEach(sortedPackages, id: \.identifier) { package in
                    PricingCard(
                        package: package,
                        offerings: offerings,
                        isSelected: selectedPackage?.identifier == package.identifier,
                        colorScheme: colorScheme
                    ) {
                        selectedPackage = package
                        HapticManager.shared.playSelection()
                    }
                }
            }
            
            // Purchase Button
            PurchaseButton(
                selectedPackage: selectedPackage,
                offerings: offerings,
                isPurchasing: isPurchasing,
                colorScheme: colorScheme,
                onTap: onPurchase
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // gradient overlay
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.4),
                                Color.clear,
                                Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.15),
            radius: 24,
            x: 0,
            y: -8
        )
        .padding(.horizontal, 16)
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

// MARK: - Pricing Card с улучшенными анимациями
struct PricingCard: View {
    let package: Package
    let offerings: Offerings
    let isSelected: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void
    
    // ИСПРАВЛЕНИЕ: Добавляем флаг для контроля анимации
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
        case .monthly: return "calendar"
        case .yearly: return "gift.fill"
        case .lifetime: return "infinity"
        }
    }
    
    private var cardTitle: String {
        switch cardType {
        case .monthly: return "paywall_monthly_plan".localized
        case .yearly: return "paywall_yearly_plan".localized
        case .lifetime: return "paywall_lifetime_plan".localized
        }
    }
    
    private var cardPrice: String {
        return package.storeProduct.localizedPriceString
    }
    
    private var badgeText: String? {
        if cardType == .yearly {
            return "-60%"
        }
        return nil
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Icon
                Image(systemName: cardIcon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .primary)
                
                Text(cardTitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                
                Text(cardPrice)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .padding(.horizontal, 8)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                cardType == .lifetime ?
                                LinearGradient(colors: [Color.orange, Color.red], startPoint: .top, endPoint: .bottom) :
                                    ProGradientColors.gradient(startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        colorScheme == .dark ?
                                        Color.white.opacity(0.08) :
                                            Color.black.opacity(0.05)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected ? Color.clear :
                            Color.primary.opacity(0.1),
                        lineWidth: 1
                    )
            )
            .overlay(
                // Floating premium badge
                Group {
                    if let badgeText = badgeText {
                        Text(badgeText)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [HabitIconColor.green.lightColor, HabitIconColor.green.darkColor],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
                                    )
                            )
                            .padding(.top, -14)
                    }
                },
                alignment: .topTrailing
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.08 : 1.0)
        // ИСПРАВЛЕНИЕ: Анимация только после появления
        .animation(hasAppeared ? .easeInOut(duration: 0.25) : .none, value: isSelected)
        .onAppear {
            // Включаем анимации через небольшую задержку
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                hasAppeared = true
            }
        }
    }
}

// MARK: - Purchase Button
struct PurchaseButton: View {
    let selectedPackage: Package?
    let offerings: Offerings
    let isPurchasing: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void
        
    private var buttonText: String {
        if isPurchasing {
            return "paywall_processing_button".localized
        }
        
        guard let selectedPackage = selectedPackage else {
            return "paywall_continue".localized
        }
        
        if selectedPackage.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase {
            return "paywall_get_lifetime".localized
        } else if selectedPackage.packageType == .annual {
            return getYearlyButtonText()
        } else {
            return "paywall_subscribe".localized
        }
    }
    
    private func getYearlyButtonText() -> String {
        guard let selectedPackage = selectedPackage else {
            return "paywall_7_days_free_trial".localized
        }
        
        let yearlyPrice = selectedPackage.storeProduct.price
        let yearlyPricePerMonth = yearlyPrice / 12
        
        // Берем валюту из самого годового пакета
        let currencySymbol = extractCurrencySymbol(from: selectedPackage.storeProduct.localizedPriceString)
        let monthlyPriceDouble = NSDecimalNumber(decimal: yearlyPricePerMonth).doubleValue
        
        let displayPrice: String
        if monthlyPriceDouble < 1 {
            displayPrice = String(format: "%.2f", monthlyPriceDouble)
        } else if monthlyPriceDouble < 10 {
            displayPrice = String(format: "%.1f", monthlyPriceDouble)
        } else {
            displayPrice = String(format: "%.0f", monthlyPriceDouble)
        }
        
        return String(format: "paywall_start_trial_monthly".localized, "\(currencySymbol)\(displayPrice)")
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
                        .tint(.white)
                }
                
                Text(buttonText)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            selectedPackage?.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase ?
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .top,
                                endPoint: .bottom
                            ) :
                                LinearGradient(
                                    colors: ProGradientColors.gradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                }
            )
            .shadow(
                color: selectedPackage?.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase ?
                Color.orange.opacity(0.4) :
                    ProGradientColors.gradientColors[0].opacity(0.4),
                radius: 12,
                x: 0,
                y: 6
            )
        }
        .buttonStyle(.plain)
        .disabled(selectedPackage == nil || isPurchasing)
        .opacity(selectedPackage == nil || isPurchasing ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isPurchasing)
    }
}

// MARK: - Helper Types
enum PricingCardType {
    case monthly, yearly, lifetime
}
