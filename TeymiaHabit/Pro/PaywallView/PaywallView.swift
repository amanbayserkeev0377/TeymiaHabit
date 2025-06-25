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
            ZStack(alignment: .bottom) {
                // Background
                PaywallBackgroundGradient(colorScheme: colorScheme)
                
                // Main Content (ScrollView)
                ScrollView {
                    VStack(spacing: 32) {
                        // Header with laurels
                        PaywallHeaderSection(colorScheme: colorScheme)
                        
                        // Features section (теперь может быть сколько угодно длинным)
                        PaywallExpandedFeaturesSection(colorScheme: colorScheme)
                        
                        // Additional content can go here
                        // Testimonials, statistics, etc.
                        
                        // Bottom padding to account for overlay
                        Color.clear
                            .frame(height: 200) // Примерная высота overlay
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
                
                // Bottom Overlay with Pricing
                if let offerings = proManager.offerings,
                   let currentOffering = offerings.current,
                   !currentOffering.availablePackages.isEmpty {
                    
                    PaywallBottomOverlay(
                        offerings: offerings,
                        selectedPackage: $selectedPackage,
                        isPurchasing: isPurchasing,
                        colorScheme: colorScheme
                    ) {
                        purchaseSelected()
                    }
                    .ignoresSafeArea(.keyboard, edges: .bottom) // Поддержка клавиатуры
                    
                } else {
                    // Fallback for loading state
                    PaywallFallbackOverlay(colorScheme: colorScheme)
                }
            }
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
    
    // MARK: - Helper Methods
    
    private func selectDefaultPackage() {
        guard let offerings = proManager.offerings,
              let currentOffering = offerings.current,
              !currentOffering.availablePackages.isEmpty else { return }
        
        // ✅ ПРИОРИТЕТ 1: Yearly план (лучший для habit tracking)
        if let yearlyPackage = currentOffering.annual {
            selectedPackage = yearlyPackage
            return
        }
        
        // ✅ ПРИОРИТЕТ 2: Yearly через packageType (на случай если .annual не работает)
        if let yearlyPackage = currentOffering.availablePackages.first(where: { $0.packageType == .annual }) {
            selectedPackage = yearlyPackage
            return
        }
        
        // ✅ ПРИОРИТЕТ 3: Lifetime (если нет yearly)
        if let lifetimePackage = currentOffering.availablePackages.first(where: {
            $0.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase
        }) {
            selectedPackage = lifetimePackage
            return
        }
        
        // ✅ ПРИОРИТЕТ 4: Fallback на первый пакет
        selectedPackage = currentOffering.availablePackages.first
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

// MARK: - Expanded Features Section (больше фичей)
struct PaywallExpandedFeaturesSection: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            // Основные фичи
            VStack(spacing: 20) {
                ForEach(ProFeature.allFeatures, id: \.id) { feature in
                    FeatureRow(feature: feature, colorScheme: colorScheme)
                }
            }
            
            // Дополнительные фичи (можно расширять)
            VStack(spacing: 16) {
                PaywallFeatureRowSimple(
                    icon: "icloud.fill",
                    title: "iCloud Sync",
                    description: "Seamless synchronization across all your devices",
                    color: .blue,
                    colorScheme: colorScheme
                )
                
                PaywallFeatureRowSimple(
                    icon: "bell.fill",
                    title: "Smart Reminders",
                    description: "Intelligent notifications to keep you on track",
                    color: .orange,
                    colorScheme: colorScheme
                )
                
                PaywallFeatureRowSimple(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Advanced Analytics",
                    description: "Detailed insights and progress tracking",
                    color: .green,
                    colorScheme: colorScheme
                )
                
                PaywallFeatureRowSimple(
                    icon: "person.2.fill",
                    title: "Family Sharing",
                    description: "Share your Pro subscription with family members",
                    color: .purple,
                    colorScheme: colorScheme
                )
            }
            
            // Footer с restore и legal (перенесли в scroll content)
            PaywallScrollableFooter(colorScheme: colorScheme) {
                // Handle restore purchases
                // Можно сделать через callback если нужно
            }
        }
    }
}

// MARK: - Simple Feature Row (для дополнительных фичей)
struct PaywallFeatureRowSimple: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Simple icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Scrollable Footer (restore + legal в content)
struct PaywallScrollableFooter: View {
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
            
            // Legal text (более компактно)
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
        .padding(.top, 32)
    }
}

// MARK: - Fallback Overlay (для loading state)
struct PaywallFallbackOverlay: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Loading subscription options...")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            ProgressView()
                .scaleEffect(1.2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
    }
}
