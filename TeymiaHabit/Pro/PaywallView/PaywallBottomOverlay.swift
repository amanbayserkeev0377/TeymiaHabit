import SwiftUI
import RevenueCat

// MARK: - Bottom Overlay с Glassmorphism
struct PaywallBottomOverlay: View {
    let offerings: Offerings
    @Binding var selectedPackage: Package?
    let isPurchasing: Bool
    let colorScheme: ColorScheme
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Compact Pricing Cards
            HStack(spacing: 12) {
                ForEach(sortedPackages, id: \.identifier) { package in
                    CompactPricingCard(
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
            
            // Adaptive Purchase Button
            AdaptivePurchaseButton(
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
            // Glassmorphism effect
            ZStack {
                // Ultra thin material для blur эффекта
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // Subtle shadow/depth effect
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        colorScheme == .dark
                            ? Color.black.opacity(0.1)
                            : Color.white.opacity(0.3)
                    )
                
                // Top border highlight
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
            radius: 20,
            x: 0,
            y: -5
        )
        .padding(.horizontal, 16)
    }
    
    // ✅ ОБНОВЛЕННЫЙ ПОРЯДОК: Monthly → Yearly → Lifetime (слева направо)
    private var sortedPackages: [Package] {
        guard let currentOffering = offerings.current else { return [] }
        
        return currentOffering.availablePackages.sorted { first, second in
            // Monthly first (слева)
            if first.packageType == .monthly && second.packageType != .monthly {
                return true
            }
            if second.packageType == .monthly && first.packageType != .monthly {
                return false
            }
            
            // Yearly second (центр)
            if first.packageType == .annual && second.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase {
                return true
            }
            if second.packageType == .annual && first.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase {
                return false
            }
            
            // Lifetime last (справа) - остается как есть
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

// MARK: - Compact Pricing Card с исправленным floating badge
struct CompactPricingCard: View {
    let package: Package
    let offerings: Offerings
    let isSelected: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void
    
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
        case .yearly: return "gift"
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
    
    // ✅ FLOATING BADGE текст
    private var badgeText: String? {
        if cardType == .yearly {
            return "Save 60%" // Можно локализовать позже
        }
        return nil
    }
    
    var body: some View {
        Button(action: onTap) {
            // ✅ ИСПРАВЛЕНО: Основная карточка в своем контейнере
            VStack(spacing: 8) {
                // Icon
                Image(systemName: cardIcon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .primary)
                
                // Title
                Text(cardTitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                
                // Price
                Text(cardPrice)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isSelected
                            ? (cardType == .lifetime ?
                                LinearGradient(colors: [Color.orange, Color.red], startPoint: .top, endPoint: .bottom) :
                                LinearGradient(
                                    colors: [
                                        Color(#colorLiteral(red: 0.4925274849, green: 0.5225450397, blue: 0.9995061755, alpha: 1)),
                                        Color(#colorLiteral(red: 0.6020479798, green: 0.4322265685, blue: 0.9930816293, alpha: 1)),
                                        Color(#colorLiteral(red: 0.8248458505, green: 0.4217056334, blue: 0.8538249135, alpha: 1))
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                              )
                            : LinearGradient(
                                colors: [
                                    colorScheme == .dark ?
                                        Color.white.opacity(0.08) :
                                        Color.black.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                              )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isSelected ? Color.clear :
                        (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1)),
                        lineWidth: 1
                    )
            )
            // ✅ ИСПРАВЛЕНО: Badge на всю ширину карточки по центру сверху
            .overlay(
                // FLOATING BADGE поверх карточки
                Group {
                    if let badgeText = badgeText {
                        Text(badgeText)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [HabitIconColor.green.lightColor, HabitIconColor.green.darkColor],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                                    )
                            )
                            .padding(.horizontal, 8) // Небольшие отступы от краев карточки
                            .padding(.top, -12) // Поднимаем над карточкой
                    }
                },
                alignment: .top
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: isSelected)
    }
}

// MARK: - Adaptive Purchase Button
struct AdaptivePurchaseButton: View {
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
            return "Continue"
        }
        
        if selectedPackage.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase {
            return "Get Lifetime"
        } else if selectedPackage.packageType == .annual {
            return getYearlyButtonText()
        } else {
            return "Subscribe"
        }
    }
    
    private func getYearlyButtonText() -> String {
        guard let selectedPackage = selectedPackage,
              let monthlyPackage = offerings.current?.availablePackages.first(where: { $0.packageType == .monthly }) else {
            return "Start Free Trial"
        }
        
        let yearlyPrice = selectedPackage.storeProduct.price
        let monthlyPrice = monthlyPackage.storeProduct.price
        
        let yearlyPricePerMonth = yearlyPrice / 12
        let savingsPercentage = ((monthlyPrice - yearlyPricePerMonth) / monthlyPrice) * 100
        
        let currencySymbol = extractCurrencySymbol(from: monthlyPackage.storeProduct.localizedPriceString)
        let monthlyPriceDouble = NSDecimalNumber(decimal: yearlyPricePerMonth).doubleValue
        
        let displayPrice: String
        if monthlyPriceDouble < 1 {
            displayPrice = String(format: "%.2f", monthlyPriceDouble)
        } else if monthlyPriceDouble < 10 {
            displayPrice = String(format: "%.1f", monthlyPriceDouble)
        } else {
            displayPrice = String(format: "%.0f", monthlyPriceDouble)
        }
        
        let savingsInt = max(1, Int(NSDecimalNumber(decimal: savingsPercentage).doubleValue))
        
        return String(format: "paywall_start_trial_monthly".localized, "\(currencySymbol)\(displayPrice)")
    }
    
    // ✅ ПРОСТАЯ функция для символа валюты
    private func extractCurrencySymbol(from priceString: String) -> String {
        // Проверяем известные символы валют
        if priceString.contains("$") { return "$" }
        if priceString.contains("€") { return "€" }
        if priceString.contains("£") { return "£" }
        if priceString.contains("₽") { return "₽" }
        if priceString.contains("¥") { return "¥" }
        if priceString.contains("₹") { return "₹" }
        if priceString.contains("₩") { return "₩" }
        
        // Если ничего не нашли, берем первый нецифровой символ
        if let currencyChar = priceString.first(where: { !$0.isNumber && !$0.isWhitespace && $0 != "." && $0 != "," }) {
            return String(currencyChar)
        }
        
        return "$" // fallback
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
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        selectedPackage?.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase ?
                        LinearGradient(colors: [Color.orange, Color.red], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(
                            colors: [
                                Color(#colorLiteral(red: 0.3609918654, green: 0.7860431075, blue: 0.9797958732, alpha: 1)),
                                Color(#colorLiteral(red: 0.4925274849, green: 0.5225450397, blue: 0.9995061755, alpha: 1)),
                                Color(#colorLiteral(red: 0.5651029348, green: 0.4914609194, blue: 0.9916761518, alpha: 1)),
                                Color(#colorLiteral(red: 0.8493401408, green: 0.3309155107, blue: 0.6768040061, alpha: 1))
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(
                color: Color.black.opacity(0.2),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPurchasing ? 0.95 : 1.0)
        .disabled(selectedPackage == nil || isPurchasing)
        .opacity(selectedPackage == nil || isPurchasing ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isPurchasing)
    }
}

// MARK: - Helper Types
enum PricingCardType {
    case monthly, yearly, lifetime
}
