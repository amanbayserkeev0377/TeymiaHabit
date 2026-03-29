import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ProManager.self) private var proManager
    
    @State private var selectedPackage: Package?
    @State private var showingAlert = false
    @State private var purchaseResult: PurchaseResult = .idle
    @State private var isPurchasing = false
    @State private var lifetimePackage: Package?
    
    private var alertMessage: LocalizedStringResource {
        switch purchaseResult {
        case .error(let message), .success(let message):
            return message
        case .idle:
            return ""
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 32) {
                    PaywallHeaderSection()
                    PaywallExpandedFeaturesSection {
                        restorePurchases()
                    }
                }
                .padding(.horizontal, 16)
            }
            .background {
                LivelyFloatingBlobsBackground()
            }
            .toolbar {
                CloseToolbarButton()
            }
            .safeAreaBar(edge: .bottom) {
                if let offerings = proManager.offerings,
                   let currentOffering = offerings.current,
                   !currentOffering.availablePackages.isEmpty {
                    
                    PaywallBottomOverlay(
                        offerings: offerings,
                        selectedPackage: $selectedPackage,
                        isPurchasing: isPurchasing,
                    ) {
                        purchaseSelected()
                    }
                } else {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("paywall_processing_button")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            selectDefaultPackage()
        }
        .alert("paywall_purchase_result_title", isPresented: $showingAlert) {
            Button("paywall_ok_button") {
                if case .success = purchaseResult {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }.tint(Color.primary)
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
                    purchaseResult = .success("paywall_purchase_success_message")
                    HapticManager.shared.play(.success)
                    dismiss()
                } else {
                    purchaseResult = .error("paywall_purchase_failed_message")
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
                    purchaseResult = .success("paywall_restore_success_message")
                    HapticManager.shared.play(.success)
                } else {
                    purchaseResult = .error("paywall_no_purchases_to_restore_message")
                    HapticManager.shared.play(.error)
                }
                showingAlert = true
            }
        }
    }
}

// MARK: - Header
struct PaywallHeaderSection: View {
    var body: some View {
        HStack {
            Text("Teymia Habit")
                .foregroundStyle(.white.gradient)
            
            Text("Pro")
                .foregroundStyle(.appOrange)
        }
        .font(.largeTitle)
        .fontWeight(.bold)
        .multilineTextAlignment(.center)
    }
}

// MARK: - Expanded Features Section

struct PaywallExpandedFeaturesSection: View {
    let onRestorePurchases: () -> Void
    var body: some View {
        VStack {
            VStack(spacing: 24) {
                ForEach(ProFeature.allFeatures, id: \.id) { feature in
                    FeatureRow(feature: feature)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .glassEffect(.clear, in: .rect(cornerRadius: 30))
            
            PaywallScrollableFooter() {
                onRestorePurchases()
            }
        }
    }
}

// MARK: - Scrollable Footer

struct PaywallScrollableFooter: View {
    @Environment(\.openURL) private var openURL
    
    let onRestorePurchases: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Button("paywall_restore_purchases_button") {
                onRestorePurchases()
            }
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundStyle(.white.gradient)
            
            Button {
                if let url = URL(string: "https://www.apple.com/family-sharing/") {
                    openURL(url, prefersInApp: true)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.3.sequence.fill")
                        .font(.system(size: 14))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.blue.gradient, .mint.gradient, .purple.gradient)
                    
                    Text("paywall_family_sharing_button")
                        .font(.subheadline)
                        .foregroundStyle(.blue.gradient)
                }
            }
            Text("paywall_legal_text")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            
            HStack(spacing: 30) {
                Button("paywall_terms_of_service") {
                    if let url = URL(string: "https://www.notion.so/Terms-of-Service-204d5178e65a80b89993e555ffd3511f") {
                        openURL(url, prefersInApp: true)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                Button("paywall_privacy_policy") {
                    if let url = URL(string: "https://www.notion.so/Privacy-Policy-1ffd5178e65a80d4b255fd5491fba4a8") {
                        openURL(url, prefersInApp: true)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 32)
    }
}

enum PurchaseResult {
    case idle
    case success(LocalizedStringResource)
    case error(LocalizedStringResource)
}
