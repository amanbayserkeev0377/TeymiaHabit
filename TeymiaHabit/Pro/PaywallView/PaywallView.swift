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
                ScrollView {
                    VStack(spacing: 32) {
                        PaywallHeaderSection()
                        PaywallExpandedFeaturesSection {
                            restorePurchases()
                        }
                        
                        Color.clear
                            .frame(height: 200)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
                
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
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    
                } else {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("paywall_processing_button".localized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    XmarkView(action: {
                        dismiss()
                    })
                }
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            selectDefaultPackage()
        }
        .alert("paywall_purchase_result_title".localized, isPresented: $showingAlert) {
            Button("paywall_ok_button".localized) {
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
        
        if let yearlyPackage = currentOffering.annual {
            selectedPackage = yearlyPackage
            return
        }
        if let yearlyPackage = currentOffering.availablePackages.first(where: { $0.packageType == .annual }) {
            selectedPackage = yearlyPackage
            return
        }
        if let lifetimePackage = currentOffering.availablePackages.first(where: {
            $0.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase
        }) {
            selectedPackage = lifetimePackage
            return
        }
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
                    dismiss()
                } else {
                    alertMessage = "paywall_no_purchases_to_restore_message".localized
                    HapticManager.shared.play(.error)
                }
                showingAlert = true
            }
        }
    }
}

// MARK: - Expanded Features Section

struct PaywallExpandedFeaturesSection: View {
    let onRestorePurchases: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 20) {
                ForEach(ProFeature.allFeatures, id: \.id) { feature in
                    FeatureRow(feature: feature)
                }
            }
            
            PaywallScrollableFooter() {
                onRestorePurchases()
            }
        }
    }
}

// MARK: - Scrollable Footer

struct PaywallScrollableFooter: View {
    let onRestorePurchases: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Button("paywall_restore_purchases_button".localized) {
                onRestorePurchases()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            
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
                                colors: [Color.purple, Color.blue, Color.mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("paywall_family_sharing_button".localized)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            Text("paywall_legal_text".localized)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            
            HStack(spacing: 30) {
                Button("terms_of_service".localized) {
                    if let url = URL(string: "https://www.notion.so/Terms-of-Service-204d5178e65a80b89993e555ffd3511f") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                Button("privacy_policy".localized) {
                    if let url = URL(string: "https://www.notion.so/Privacy-Policy-1ffd5178e65a80d4b255fd5491fba4a8") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 32)
    }
}
