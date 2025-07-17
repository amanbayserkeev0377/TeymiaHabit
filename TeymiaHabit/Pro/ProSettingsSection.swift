import SwiftUI

struct ProSettingsSection: View {
    @Environment(ProManager.self) private var proManager
    @State private var showingPaywall = false
    @State private var isStartingTrial = false // ⭐ Добавляем состояние загрузки
    
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
                // Верхняя часть - иконка и заголовки
                HStack(spacing: 12) {
                    Image("3d_star_progradient")
                        .resizable()
                        .frame(width: 60, height: 60)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Teymia Habit Pro")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text("paywall_unlock_premium".localized)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                // ⭐ УЛУЧШЕННАЯ кнопка FREE TRIAL
                FreeTrialButton(
                    isLoading: $isStartingTrial,
                    onTap: {
                        startFreeTrial()
                    }
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(ProGradientColors.proGradient)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 0.7)
                    
                    RoundedRectangle(cornerRadius: 16)
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
    
    // MARK: - Start Free Trial
    private func startFreeTrial() {
        guard !isStartingTrial else { return }
        
        isStartingTrial = true
        HapticManager.shared.playImpact(.medium)
        
        Task {
            guard let offerings = proManager.offerings,
                  let currentOffering = offerings.current else {
                print("❌ No offerings available for free trial")
                await MainActor.run {
                    isStartingTrial = false
                    HapticManager.shared.play(.error)
                }
                return
            }
            
            let yearlyPackage = currentOffering.annual ??
                               currentOffering.availablePackages.first { $0.packageType == .annual }
            
            guard let package = yearlyPackage else {
                print("❌ Yearly package not found for free trial")
                await MainActor.run {
                    isStartingTrial = false
                    HapticManager.shared.play(.error)
                }
                return
            }
            
            print("🎯 Starting free trial with yearly package: \(package.storeProduct.localizedTitle)")
            
            let success = await proManager.purchase(package: package)
            
            await MainActor.run {
                isStartingTrial = false
                
                if success {
                    print("✅ Free trial started successfully!")
                    HapticManager.shared.play(.success)
                } else {
                    print("❌ Free trial purchase failed")
                    HapticManager.shared.play(.error)
                }
            }
        }
    }
}

// MARK: - Отдельный компонент кнопки
struct FreeTrialButton: View {
    @Binding var isLoading: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 10) {
                Spacer()
                
                Group {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .frame(width: 20, height: 20)
                
                Text(isLoading ? "paywall_processing_button".localized : "paywall_7_days_free_trial".localized)
                    .font(.title3)
                    .fontWeight(.bold)
                    .animation(.easeInOut(duration: 0.2), value: isLoading)
                
                Spacer()
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(isPressed ? 0.15 : 0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.4), lineWidth: 0.7)
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
