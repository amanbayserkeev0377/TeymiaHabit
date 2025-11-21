import SwiftUI

struct ProSettingsSection: View {
    @Environment(ProManager.self) private var proManager
    @State private var showingPaywall = false
    @State private var isStartingTrial = false
    
    var body: some View {
        Section {
            if !proManager.isPro {
                proPromoView
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Pro Promo View
    private var proPromoView: some View {
        Button {
            showingPaywall = true
        } label: {
            VStack {
                HStack {
                    Image("sparkles.pro")
                        .resizable()
                        .frame(width: 36, height: 36)
                        .foregroundStyle(.white.gradient)
                    
                    VStack(alignment: .leading) {
                        Text("Teymia Habit Pro")
                            .font(.title3)
                            .fontWeight(.bold)
                            .fontDesign(.rounded)
                            .foregroundStyle(.white.gradient)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text("paywall_unlock_premium".localized)
                            .font(.footnote)
                            .fontDesign(.rounded)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    
                    Spacer()
                    
                    FreeTrialButton()
                }
                .shimmer(.init(tint: .white.opacity(0.7), highlight: .white, blur: 5))
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(ProGradientColors.proGradient)
                    
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.4), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .blendMode(.overlay)
                }
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Free Trial
    private func startFreeTrial() {
        guard !isStartingTrial else { return }
        
        isStartingTrial = true
        HapticManager.shared.playImpact(.medium)
        
        Task {
            guard let offerings = proManager.offerings,
                  let currentOffering = offerings.current else {
                await MainActor.run {
                    isStartingTrial = false
                    HapticManager.shared.play(.error)
                }
                return
            }
            
            let yearlyPackage = currentOffering.annual ??
            currentOffering.availablePackages.first { $0.packageType == .annual }
            
            guard let package = yearlyPackage else {
                await MainActor.run {
                    isStartingTrial = false
                    HapticManager.shared.play(.error)
                }
                return
            }
            
            let success = await proManager.purchase(package: package)
            
            await MainActor.run {
                isStartingTrial = false
                
                if success {
                    HapticManager.shared.play(.success)
                } else {
                    HapticManager.shared.play(.error)
                }
            }
        }
    }
}

// MARK: - Free Trial Button
struct FreeTrialButton: View {
    
    var body: some View {
        HStack(spacing: 4) {
            Image("gift.fill")
                .resizable()
                .frame(width: 16, height: 16)
            
            Text("paywall_7_days_free_trial".localized)
                .font(.footnote)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(.white.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(.white.opacity(0.5), lineWidth: 0.7)
                )
        )
    }
}
