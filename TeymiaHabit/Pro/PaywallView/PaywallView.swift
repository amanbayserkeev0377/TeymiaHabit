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
                    PaywallHeaderSection(colorScheme: colorScheme)
                    
                    // Features grid
                    PaywallFeaturesSection(colorScheme: colorScheme)
                    
                    // Pricing options
                    if let offerings = proManager.offerings,
                       let currentOffering = offerings.current,
                       !currentOffering.availablePackages.isEmpty {
                        pricingSection(currentOffering)
                    } else {
                        // Fallback UI for Apple reviewers
                        PaywallFallbackView()
                    }
                    
                    // Purchase button
                    PaywallPurchaseButton(
                        selectedPackage: selectedPackage,
                        isPurchasing: isPurchasing,
                        colorScheme: colorScheme
                    ) {
                        purchaseSelected()
                    }
                    
                    // Restore and legal
                    PaywallFooterSection(colorScheme: colorScheme) {
                        restorePurchases()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .background(PaywallBackgroundGradient(colorScheme: colorScheme))
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
    
    // MARK: - Helper Methods
    
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
