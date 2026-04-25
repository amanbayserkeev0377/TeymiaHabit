import SwiftUI

// MARK: - Constants

private extension ThemeChangeView {
    enum Metrics {
        static let rayCornerRadius = Radius.sm
        static let pickerTopPadding = Spacing.lg
        static let pickerHorizontalPadding = Spacing.xl
        static let containerVerticalPadding = Spacing.lg
        static let containerSpacing = Spacing.md
        
        static let glowSize: CGFloat = 130
        static let glowBlur: CGFloat = 40
        static let rayWidth: CGFloat = 10
        static let rayHeight: CGFloat = 35
        static let rayOffset: CGFloat = -110
        static let rayCount: Int = 8
        static let rayGlowRadius: CGFloat = 5
        static let circleSize: CGFloat = 150
        static let circleShadowRadius: CGFloat = 25
        static let circleShadowY: CGFloat = 10
        static let borderLineWidth: CGFloat = 1
        static let animationHeight: CGFloat = 300
        static let darkMaskOffset = CGSize(width: 35, height: -30)
        static let lightMaskOffset = CGSize(width: 150, height: -150)
        static let darkGlowOpacity: CGFloat = 0.2
        static let lightGlowOpacity: CGFloat = 0.4
        static let darkRayOpacity: CGFloat = 0
        static let lightRayOpacity: CGFloat = 1
        static let darkRayScale: CGFloat = 0.5
        static let lightRayScale: CGFloat = 1
        static let shadowOpacity: CGFloat = 0.5
        static let rayGlowOpacity: CGFloat = 0.3
    }
    
    static let borderGradient = LinearGradient(
        colors: [
            .white.opacity(0.6),
            .white.opacity(0.2),
            .white.opacity(0.2),
            .white.opacity(0.6)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Main View

struct ThemeChangeView: View {
    static let sheetHeight: CGFloat = 450
    
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    @Environment(\.colorScheme) private var scheme
    @State private var circleOffset: CGSize = .zero
    
    private var isDark: Bool {
        themeMode.resolvedIsDark(systemScheme: scheme)
    }
    
    var body: some View {
        VStack(spacing: Metrics.containerSpacing) {
            themeIllustration
                .frame(height: Metrics.animationHeight)
                .animation(.themeSpring, value: isDark)
            themePicker
        }
        .padding(.vertical, Metrics.containerVerticalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.default, value: scheme)
        .onAppear { updateOffset(animated: false) }
        .onChange(of: scheme) { _, _ in updateOffset(animated: true) }
        .onChange(of: themeMode) { _, _ in updateOffset(animated: true) }
    }
    
    // MARK: - Subviews
    
    private var themeIllustration: some View {
        ZStack {
            glowBackground
            sunRays
            shadowRing
            mainCircle
        }
    }
    
    private var glowBackground: some View {
        Circle()
            .fill(themeMode.glowColor(scheme))
            .frame(width: Metrics.glowSize, height: Metrics.glowSize)
            .blur(radius: Metrics.glowBlur)
            .opacity(isDark ? Metrics.darkGlowOpacity : Metrics.lightGlowOpacity)
    }
    
    private var sunRays: some View {
        ForEach(0..<Metrics.rayCount, id: \.self) { index in
            Rectangle()
                .fill(themeMode.gradient(scheme))
                .frame(width: Metrics.rayWidth, height: Metrics.rayHeight)
                .cornerRadius(Metrics.rayCornerRadius)
                .shadow(
                    color: themeMode.glowColor(scheme).opacity(isDark ? 0 : Metrics.rayGlowOpacity),
                    radius: Metrics.rayGlowRadius
                )
                .offset(y: Metrics.rayOffset)
                .rotationEffect(.degrees(Double(index) * (360.0 / Double(Metrics.rayCount))))
                .opacity(isDark ? Metrics.darkRayOpacity : Metrics.lightRayOpacity)
                .scaleEffect(isDark ? Metrics.darkRayScale : Metrics.lightRayScale)
        }
    }
    
    // Invisible circle used purely to cast a shadow behind the main circle
    private var shadowRing: some View {
        Circle()
            .fill(Color.black.opacity(0.01))
            .frame(width: Metrics.circleSize, height: Metrics.circleSize)
            .shadow(
                color: themeMode.glowColor(scheme).opacity(Metrics.shadowOpacity),
                radius: Metrics.circleShadowRadius,
                x: 0,
                y: Metrics.circleShadowY
            )
    }
    
    private var mainCircle: some View {
        Circle()
            .fill(themeMode.gradient(scheme))
            .frame(width: Metrics.circleSize, height: Metrics.circleSize)
            .overlay {
                Circle().stroke(Self.borderGradient, lineWidth: Metrics.borderLineWidth)
            }
            .mask {
                Rectangle()
                    .overlay {
                        Circle()
                            .offset(circleOffset)
                            .blendMode(.destinationOut)
                    }
            }
    }
    
    private var themePicker: some View {
        Picker("", selection: $themeMode) {
            ForEach(ThemeMode.allCases, id: \.self) { theme in
                Text(theme.localizedName).tag(theme)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Metrics.pickerHorizontalPadding)
        .padding(.top, Metrics.pickerTopPadding)
    }
    
    // MARK: - Helpers
    
    private func updateOffset(animated: Bool) {
        let newOffset = isDark ? Metrics.darkMaskOffset : Metrics.lightMaskOffset
        if animated {
            withAnimation(.themeBounce) {
                circleOffset = newOffset
            }
        } else {
            circleOffset = newOffset
        }
    }
}
