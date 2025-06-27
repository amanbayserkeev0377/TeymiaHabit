import SwiftUI

// MARK: - What's New Feature Data
struct WhatsNewFeature {
    let icon: String
    let title: String
    let description: String
    let habitColor: HabitIconColor // ✅ Изменили с Color на HabitIconColor
    
    init(icon: String, title: String, description: String, habitColor: HabitIconColor) {
        self.icon = icon
        self.title = title
        self.description = description
        self.habitColor = habitColor
    }
}

// MARK: - What's New View
struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = 30
    @State private var featuresOpacity: Double = 0
    @State private var featuresOffset: CGFloat = 30
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 30
    
    // MARK: - Features for Version 1.1 - ✅ обновленные с HabitIconColor
    private let features: [WhatsNewFeature] = [
        WhatsNewFeature(
            icon: "chart.line.uptrend.xyaxis",
            title: "whats_new_statistics_title".localized,
            description: "whats_new_statistics_description".localized,
            habitColor: .blue // Аналитика и данные
        ),
        WhatsNewFeature(
            icon: "paintbrush.pointed.fill",
            title: "whats_new_colorful_rings_title".localized,
            description: "whats_new_colorful_rings_description".localized,
            habitColor: .purple // Креативность и дизайн
        ),
    ]
    
    var body: some View {
        ZStack {
            // Full screen gradient background
            backgroundGradient
            
            VStack(spacing: 0) {
                Spacer().frame(height: 60) // Отступ сверху вместо кнопки закрытия
                
                // Content
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    Spacer().frame(height: 50)
                    
                    // Features - compact layout
                    featuresSection
                    
                    Spacer()
                    
                    // Continue Button
                    continueButton
                    
                    Spacer().frame(height: 50)
                }
            }
        }
        .onAppear {
            // Поэтапное появление с красивыми задержками как в EmptyStateView
            isAnimating = true
            
            // 1. Заголовок появляется первым
            withAnimation(.easeOut(duration: 1.5).delay(0.8)) {
                titleOpacity = 1.0
                titleOffset = 0
            }
            
            // 2. Подзаголовок появляется вторым
            withAnimation(.easeOut(duration: 1.5).delay(1.6)) {
                subtitleOpacity = 1.0
                subtitleOffset = 0
            }
            
            // 3. Фичи появляются третьими
            withAnimation(.easeOut(duration: 1.2).delay(2.4)) {
                featuresOpacity = 1.0
                featuresOffset = 0
            }
            
            // 4. Кнопка появляется последней
            withAnimation(.easeOut(duration: 1.0).delay(3.2)) {
                buttonOpacity = 1.0
                buttonOffset = 0
            }
        }
    }
    
    // MARK: - Background Gradient (адаптивный под темы)
    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark ? [
                // Темная тема - темные тона
                Color(#colorLiteral(red: 0.1215686275, green: 0.1294117647, blue: 0.1607843137, alpha: 1)), // Темно-серый с фиолетовым
                Color(#colorLiteral(red: 0.1568627451, green: 0.1647058824, blue: 0.2196078431, alpha: 1)), // Темно-синий
                Color(#colorLiteral(red: 0.1843137255, green: 0.1725490196, blue: 0.2588235294, alpha: 1))  // Темно-фиолетовый
            ] : [
                // Светлая тема - мягкие светлые тона
                Color(#colorLiteral(red: 0.9098039216, green: 0.9176470588, blue: 0.9647058824, alpha: 1)), // Очень светлый лавандовый
                Color(#colorLiteral(red: 0.8235294118, green: 0.8470588235, blue: 0.9215686275, alpha: 1)), // Мягкий фиолетовый
                Color(#colorLiteral(red: 0.7450980392, green: 0.7803921569, blue: 0.8784313725, alpha: 1))  // Чуть темнее
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 24) {
            // App Icon - увеличенная с красивой анимацией
            Image("TeymiaHabitBlank") // Твоя иконка без фона
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120) // Увеличили с 80 до 120
                .scaleEffect(isAnimating ? 1.15 : 0.9)
                .animation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            // Title and subtitle с поэтапной анимацией
            VStack(spacing: 12) {
                Text("whats_new_title_full".localized) // "What's New in"
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)
                
                Text("whats_new_version".localized) // "Version 1.1"
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .opacity(subtitleOpacity)
                    .offset(y: subtitleOffset)
            }
        }
    }
    
    // MARK: - Features Section - компактный layout
    private var featuresSection: some View {
        VStack(spacing: 24) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                featureRow(feature, index: index)
            }
        }
        .padding(.horizontal, 32)
        .opacity(featuresOpacity)
        .offset(y: featuresOffset)
    }
    
    // MARK: - Feature Row - ✅ используем единую логику градиентов
    private func featureRow(_ feature: WhatsNewFeature, index: Int) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon - ✅ единая логика для всех иконок
            Image(systemName: feature.icon)
                .withAdaptiveGradientCircle(
                    habitColor: feature.habitColor,
                    colorScheme: colorScheme,
                    size: 48,
                    iconSize: 20
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Continue Button - ✅ используем цвет приложения
    private var continueButton: some View {
        Button {
            markAsSeenAndDismiss()
        } label: {
            HStack(spacing: 12) {
                Text("whats_new_continue_button".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 18, weight: .medium))
            }
        }
        .beautifulButton(
            isEnabled: true,
            lightOpacity: 0.9,
            darkOpacity: 1.0
        )
        .padding(.horizontal, 32)
        .opacity(buttonOpacity)
        .offset(y: buttonOffset)
    }
    
    // MARK: - Actions
    private func markAsSeenAndDismiss() {
        WhatsNewManager.markAsSeen()
        HapticManager.shared.play(.success) // ✅ Оставляем .success - это важное завершающее действие
        dismiss()
    }
}

// MARK: - ✅ Adaptive Gradient Circle Modifier (с единой логикой)
struct AdaptiveGradientCircleModifier: ViewModifier {
    let habitColor: HabitIconColor
    let colorScheme: ColorScheme
    let size: CGFloat
    let iconSize: CGFloat
    
    func body(content: Content) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark ? [
                            // ТЕМНАЯ тема: темный → светлый
                            habitColor.darkColor,
                            habitColor.lightColor.opacity(0.8)
                        ] : [
                            // СВЕТЛАЯ тема: светлый → темный
                            habitColor.lightColor.opacity(0.8),
                            habitColor.darkColor
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            content
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - ✅ Обновленные расширения
extension View {
    /// ✅ Новый метод с адаптивным градиентом по единой логике
    func withAdaptiveGradientCircle(
        habitColor: HabitIconColor,
        colorScheme: ColorScheme,
        size: CGFloat = 48,
        iconSize: CGFloat = 20
    ) -> some View {
        modifier(AdaptiveGradientCircleModifier(
            habitColor: habitColor,
            colorScheme: colorScheme,
            size: size,
            iconSize: iconSize
        ))
    }
    
    /// ✅ Обновленный метод с единой логикой (для обратной совместимости)
    func withGradientCircle(
        colors: [Color],
        startPoint: UnitPoint = .top,
        endPoint: UnitPoint = .bottom,
        size: CGFloat = 48,
        iconSize: CGFloat = 20
    ) -> some View {
        modifier(GradientCircleModifier(
            gradientColors: colors,
            startPoint: startPoint,
            endPoint: endPoint,
            size: size,
            iconSize: iconSize
        ))
    }
    
    func withColoredCircle(
        color: Color,
        size: CGFloat = 48,
        iconSize: CGFloat = 20
    ) -> some View {
        modifier(ColoredCircleModifier(
            color: color,
            size: size,
            iconSize: iconSize
        ))
    }
}

// MARK: - Legacy Gradient Circle Modifier (для обратной совместимости)
struct GradientCircleModifier: ViewModifier {
    let gradientColors: [Color]
    let startPoint: UnitPoint
    let endPoint: UnitPoint
    let size: CGFloat
    let iconSize: CGFloat
    
    func body(content: Content) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: startPoint,
                        endPoint: endPoint
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            content
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}

struct ColoredCircleModifier: ViewModifier {
    let color: Color
    let size: CGFloat
    let iconSize: CGFloat
    
    func body(content: Content) -> some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            content
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - What's New Manager (без изменений)
struct WhatsNewManager {
    private static let currentVersion = "1.1.0"
    private static let whatsNewKey = "hasSeenWhatsNew_\(currentVersion.replacingOccurrences(of: ".", with: "_"))"
    
    static func shouldShowWhatsNew() -> Bool {
        #if DEBUG
        if Bundle.main.bundleIdentifier?.contains("dev") == true {
            return true
        }
        #endif
        
        if UserDefaults.standard.bool(forKey: whatsNewKey) {
            return false
        }
        
        let lastVersion = UserDefaults.standard.string(forKey: "lastAppVersion") ?? "1.0.0"
        let currentAppVersion = Bundle.main.appVersion ?? currentVersion
        
        print("🆕 What's New Check: Last=\(lastVersion), Current=\(currentAppVersion)")
        
        let shouldShow = isVersionUpgrade(from: lastVersion, to: currentAppVersion)
        
        if shouldShow {
            print("✅ Should show What's New for version \(currentVersion)")
        } else {
            print("❌ No need to show What's New")
        }
        
        return shouldShow
    }
    
    static func markAsSeen() {
        UserDefaults.standard.set(true, forKey: whatsNewKey)
        UserDefaults.standard.set(Bundle.main.appVersion, forKey: "lastAppVersion")
        print("✅ What's New marked as seen for version \(currentVersion)")
    }
    
    private static func isVersionUpgrade(from lastVersion: String, to currentVersion: String) -> Bool {
        if currentVersion.starts(with: "1.1") {
            return lastVersion.starts(with: "1.0") || lastVersion.isEmpty
        }
        return false
    }
    
    #if DEBUG
    static func resetWhatsNewState() {
        UserDefaults.standard.removeObject(forKey: whatsNewKey)
        UserDefaults.standard.removeObject(forKey: "lastAppVersion")
        print("🔄 What's New state reset")
    }
    
    static func forceShow() {
        resetWhatsNewState()
        print("🚀 Forced What's New reset")
    }
    #endif
}

extension Bundle {
    var appVersion: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

#Preview {
    WhatsNewView()
}
