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
    
    // MARK: - Pro Promo View (ЧИСТАЯ ВЕРСИЯ)
    private var proPromoView: some View {
        Button {
            showingPaywall = true
        } label: {
            VStack(spacing: 16) {
                // Верхняя часть - основная информация
                HStack(spacing: 16) {
                    // Левая иконка с объемным эффектом
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    
                    // Центральный контент
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Teymia Habit Pro")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Text("paywall_7_days_free_trial".localized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    // ✅ FREE TRIAL кнопка справа
                    Button {
                        startFreeTrial()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text("FREE TRIAL")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white.opacity(0.25))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 20)
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
            // Объемная тень
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Start Free Trial (прямо запускает покупку yearly)
    private func startFreeTrial() {
        Task {
            // Ищем yearly package в offerings
            guard let offerings = proManager.offerings,
                  let currentOffering = offerings.current else {
                print("❌ No offerings available for free trial")
                return
            }
            
            // Ищем yearly пакет (который содержит free trial)
            let yearlyPackage = currentOffering.annual ??
                               currentOffering.availablePackages.first { $0.packageType == .annual }
            
            guard let package = yearlyPackage else {
                print("❌ Yearly package not found for free trial")
                return
            }
            
            print("🎯 Starting free trial with yearly package: \(package.storeProduct.localizedTitle)")
            
            // Запускаем покупку yearly подписки (с free trial)
            let success = await proManager.purchase(package: package)
            
            if success {
                print("✅ Free trial started successfully!")
                // Показываем success haptic
                HapticManager.shared.play(.success)
            } else {
                print("❌ Free trial purchase failed")
                // Показываем error haptic
                HapticManager.shared.play(.error)
            }
        }
    }
}
