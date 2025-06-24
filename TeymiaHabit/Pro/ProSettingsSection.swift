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
    
    // MARK: - Pro Promo View (УЛУЧШЕННАЯ ВЕРСИЯ)
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
                        HStack {
                            Text("Teymia Habit Pro")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            // Правая стрелочка
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        
                        Text("paywall_7_days_free_trial".localized)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                
                // Нижняя часть - FREE TRIAL кнопка
                HStack(spacing: 12) {
                    // FREE TRIAL кнопка - сразу запускает yearly подписку
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
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.25))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // Дополнительная информация - статичная (пока без ProManager расширения)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("7 days")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Text("then $19.99/year")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20) // Увеличили с 16 до 20 для большей высоты
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
            .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1) // Тонкая тень для четкости
        }
        .buttonStyle(.plain)
        .scaleEffect(1.0) // Убираем автоматический scale effect от Button
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
