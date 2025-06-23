import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ProManager.self) private var proManager
    
    @State private var selectedPackage: Package?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isPurchasing = false
    @State private var lifetimePackage: Package?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header with laurels and app icon
                    headerSection
                    
                    // Features grid
                    featuresSection
                    
                    // Pricing options
                    if let offerings = proManager.offerings,
                       let currentOffering = offerings.current,
                       !currentOffering.availablePackages.isEmpty {
                        pricingSection(currentOffering)
                    } else {
                        // Fallback UI for Apple reviewers
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
                    
                    // Purchase button
                    purchaseButton
                    
                    // Restore and legal
                    footerSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .background(backgroundGradient)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    XmarkView(action: {
                        dismiss()
                    })
                }
            }
        }
        .onAppear {
            selectDefaultPackage()
        }
        .alert("paywall_purchase_result_title".localized, isPresented: $showingAlert) {
            Button("button_ok") {
                if alertMessage.contains("successful") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Background Gradient (те же цвета что в WhatsNew)
    private var backgroundGradient: some View {
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
    
    // MARK: - Header Section
    private var headerSection: some View {
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
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(spacing: 20) {
            ForEach(ProFeature.allFeatures, id: \.id) { feature in
                FeatureRow(feature: feature, colorScheme: colorScheme)
            }
        }
    }
    
    // MARK: - Pricing Section
    private func pricingSection(_ offering: Offering) -> some View {
        VStack(spacing: 16) {
#if DEBUG
            Text("DEBUG: \(offering.availablePackages.count) packages available")
                .font(.caption)
                .foregroundStyle(.red)
#endif
            // Sort packages: Lifetime first, then Yearly, then Monthly
            let sortedPackages = offering.availablePackages.sorted { first, second in
                // Lifetime first
                if first.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase {
                    return true
                }
                if second.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase {
                    return false
                }
                // Then Yearly before Monthly
                if first.packageType == .annual && second.packageType == .monthly {
                    return true
                }
                if first.packageType == .monthly && second.packageType == .annual {
                    return false
                }
                return false
            }
            
            ForEach(sortedPackages, id: \.identifier) { package in
                // Check if this is lifetime package
                if package.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase {
                    // Show Lifetime card
                    LifetimePricingCard(
                        package: package,
                        isSelected: selectedPackage?.identifier == package.identifier,
                        colorScheme: colorScheme
                    ) {
                        selectedPackage = package
                        HapticManager.shared.playSelection()
                    }
                } else {
                    // Show regular subscription card
                    PricingCard(
                        package: package,
                        isSelected: selectedPackage?.identifier == package.identifier,
                        offering: offering,
                        colorScheme: colorScheme
                    ) {
                        selectedPackage = package
                        HapticManager.shared.playSelection()
                    }
                }
            }
        }
    }
    
    // MARK: - Purchase Button (красивая как в WhatsNew)
    private var purchaseButton: some View {
        Button {
            purchaseSelected()
        } label: {
            HStack(spacing: 12) {
                if isPurchasing {
                    ProgressView()
                        .scaleEffect(0.9)
                        .tint(colorScheme == .dark ? .white : .black)
                } else {
                    Image(systemName: isLifetimeSelected ? "infinity" : "star.fill")
                        .font(.system(size: 18, weight: .medium))
                }
                
                Text(buttonText)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(colorScheme == .dark ? .white : .black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: colorScheme == .dark ? [
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.05)
                    ] : [
                        Color.black.opacity(0.08),
                        Color.black.opacity(0.04)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        colorScheme == .dark
                            ? Color.white.opacity(0.2)
                            : Color.black.opacity(0.15),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .scaleEffect(isPurchasing ? 0.95 : 1.0)
        .disabled(selectedPackage == nil || isPurchasing)
        .opacity(selectedPackage == nil || isPurchasing ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isPurchasing)
    }
    
    private var isLifetimeSelected: Bool {
        guard let selectedPackage = selectedPackage else { return false }
        return selectedPackage.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase
    }
    
    private var buttonText: String {
        if isPurchasing {
            return "paywall_processing_button".localized
        }
        
        guard let selectedPackage = selectedPackage else {
            return "paywall_subscribe_button".localized
        }
        
        if isLifetimeSelected {
            return "paywall_get_lifetime_button".localized
        } else if selectedPackage.packageType == .annual {
            return "paywall_start_free_trial_button".localized
        } else {
            return "paywall_subscribe_button".localized
        }
    }
    
    // MARK: - Footer Section (адаптивный текст)
    private var footerSection: some View {
        VStack(spacing: 20) {
            // Restore button
            Button("paywall_restore_purchases_button".localized) {
                restorePurchases()
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
    
    // MARK: - Helper Methods (остаются те же)
    
    private func selectDefaultPackage() {
        guard let offerings = proManager.offerings,
              let currentOffering = offerings.current,
              !currentOffering.availablePackages.isEmpty else { return }
        
        // Find lifetime first
        if let lifetimePackage = currentOffering.availablePackages.first(where: {
            $0.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase
        }) {
            selectedPackage = lifetimePackage
            return
        }
        
        // Otherwise prefer yearly, fallback to first package
        if let yearlyPackage = currentOffering.annual {
            selectedPackage = yearlyPackage
        } else {
            selectedPackage = currentOffering.availablePackages.first
        }
    }
    
    private func purchaseSelected() {
        guard let package = selectedPackage, !isPurchasing else { return }
        
        isPurchasing = true
        HapticManager.shared.playImpact(.medium)
        
        Task {
            let success = await proManager.purchase(package: package)
            
            await MainActor.run {
                isPurchasing = false
                
                if success {
                    HapticManager.shared.play(.success)
                    dismiss()
                } else {
                    alertMessage = "paywall_purchase_failed_message".localized
                    HapticManager.shared.play(.error)
                    showingAlert = true
                }
            }
        }
    }
    
    private func restorePurchases() {
        isPurchasing = true
        
        Task {
            let success = await proManager.restorePurchases()
            
            await MainActor.run {
                isPurchasing = false
                
                if success {
                    alertMessage = "paywall_restore_success_message".localized
                    HapticManager.shared.play(.success)
                } else {
                    alertMessage = "paywall_no_purchases_to_restore_message".localized
                }
                showingAlert = true
            }
        }
    }
}

// MARK: - Pro Feature Model (остается тот же)
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

// MARK: - Feature Row (адаптивный текст)
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

// MARK: - Pricing Card (адаптивные цвета)
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

// MARK: - Lifetime Pricing Card (адаптивная)
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
