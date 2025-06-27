import SwiftUI

struct ProSettingsSection: View {
    @Environment(ProManager.self) private var proManager
    @State private var showingPaywall = false
    
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
    
    // MARK: - Pro Promo View (ПРОСТАЯ ВЕРСИЯ с высококонверсионными текстами)
    private var proPromoView: some View {
        Button {
            showingPaywall = true
        } label: {
            VStack(spacing: 16) {
                // Верхняя часть - иконка и заголовки
                HStack(spacing: 12) {
                    // Левая иконка - прям слева
                    Image("3d_star_progradient")
                        .resizable()
                        .frame(width: 60, height: 60)
                    
                    // Текстовая информация
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Get Teymia Habit Pro")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text("Unlock unlimited habits & premium features")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                // Нижняя часть - FREE TRIAL кнопка на всю ширину
                Button {
                    startFreeTrial()
                } label: {
                    HStack(spacing: 10) {
                        Spacer()
                        
                        Image(systemName: "gift.fill")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("Start Free Trial")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.white.opacity(0.25))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.white.opacity(0.4), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(
                // Многослойный background для объема
                ZStack {
                    // Основной градиент
                    RoundedRectangle(cornerRadius: 16)
                        .fill(ProGradientColors.proGradient)
                    
                    // Тонкая граница для объема
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear, .black.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                    
                    // Внутренний световой эффект вверху
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .clear],
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
    
    // MARK: - Start Free Trial (прямо запускает покупку yearly)
    private func startFreeTrial() {
        Task {
            // Search for yearly package in offerings
            guard let offerings = proManager.offerings,
                  let currentOffering = offerings.current else {
                print("❌ No offerings available for free trial")
                return
            }
            
            // Find yearly package (which contains free trial)
            let yearlyPackage = currentOffering.annual ??
                               currentOffering.availablePackages.first { $0.packageType == .annual }
            
            guard let package = yearlyPackage else {
                print("❌ Yearly package not found for free trial")
                return
            }
            
            print("🎯 Starting free trial with yearly package: \(package.storeProduct.localizedTitle)")
            
            // Launch yearly subscription purchase (with free trial)
            let success = await proManager.purchase(package: package)
            
            if success {
                print("✅ Free trial started successfully!")
                // Show success haptic
                HapticManager.shared.play(.success)
            } else {
                print("❌ Free trial purchase failed")
                // Show error haptic
                HapticManager.shared.play(.error)
            }
        }
    }
}
