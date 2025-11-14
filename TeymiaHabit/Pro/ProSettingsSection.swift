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
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image("diamond.pro")
                        .resizable()
                        .frame(width: 60, height: 60)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Teymia Habit Pro")
                            .font(.title2)
                            .fontWeight(.bold)
                            .fontDesign(.rounded)
                            .foregroundStyle(.white.gradient)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text("paywall_unlock_premium".localized)
                            .font(.subheadline)
                            .fontDesign(.rounded)
                            .foregroundStyle(.white.gradient.opacity(0.85))
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Image("chevron.right")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.white.gradient.opacity(0.4))
                }
                
                FreeTrialButton(
                    isLoading: $isStartingTrial,
                    onTap: startFreeTrial
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(ProGradientColors.proGradient)
                    
                    RoundedRectangle(cornerRadius: 30)
                        .strokeBorder(Color.secondary.opacity(0.5), lineWidth: 0.8)
                    
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
    @Binding var isLoading: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Spacer()
                
                Group {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image("gift.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                }
                .frame(width: 20, height: 20)
                
                Text(isLoading ? "paywall_processing_button".localized : "paywall_7_days_free_trial".localized)
                    .font(.title3)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .animation(.easeInOut(duration: 0.2), value: isLoading)
                
                Spacer()
            }
            .foregroundStyle(.white.gradient)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .fill(.white.opacity(isPressed ? 0.15 : 0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(.white.opacity(0.4), lineWidth: 0.8)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .opacity(isLoading ? 0.8 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed && !isLoading {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}
