import SwiftUI
import SwiftData

struct ProgressRing: View {
    let progress: Double
    let currentValue: String
    let isCompleted: Bool
    let isExceeded: Bool
    let habit: Habit
    var size: CGFloat
    var isTimerRunning: Bool = false
    var lineWidth: CGFloat? = nil
    var hideContent: Bool = false
    
    // MARK: - Adaptive Properties
    private var adaptiveLineWidth: CGFloat { lineWidth ?? (size * 0.12) }
    
    private var colors: (dark: Color, light: Color) {
        if let hex = habit.hexColor {
            let color = Color(hex: hex)
            return (color.darkened(by: 0.05), color.lightened(by: 0.4))
        }
        return (habit.iconColor.darkColor, habit.iconColor.lightColor)
    }
    
    var body: some View {
        let ringOffset = -size / 2
        
        ZStack {
            // 1. Background Ring
            Circle()
                .stroke(Color.gray.opacity(0.1), lineWidth: adaptiveLineWidth)
            
            // 2. Main Ring (Progress)
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    AngularGradient(
                        colors: [colors.light, colors.dark, colors.dark, colors.light],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: adaptiveLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
            
            // 3. Overflow Group (Second lap)
            Group {
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(
                        AngularGradient(colors: [colors.dark, colors.light], center: .center),
                        style: StrokeStyle(lineWidth: adaptiveLineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .rotationEffect(.degrees(360 * (progress - 1)))
                    .animation(.easeInOut(duration: 0.3), value: progress)
                
                // Overflow Cap
                Circle()
                    .frame(width: adaptiveLineWidth, height: adaptiveLineWidth)
                    .offset(y: ringOffset)
                    .foregroundStyle(colors.light)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: adaptiveLineWidth / 2.5, y: 0)
                    .rotationEffect(.degrees(360 * progress))
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
            .opacity(progress > 1 ? 1 : 0)
            .animation(.easeInOut(duration: 0.1), value: progress)
            
            if !hideContent {
                ringContent
            }
        }
        .frame(width: size, height: size)
    }
    
    @ViewBuilder
    private var ringContent: some View {
        if size < 80 {
            compactContent
        } else {
            detailContent
        }
    }
    
    @ViewBuilder
    private var compactContent: some View {
        if isCompleted || isExceeded {
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(habit.actualColor.gradient)
                .transition(.symbolEffect(.drawOn))
        } else {
            let iconName = habit.type == .count ? "plus" : (isTimerRunning ? "pause.fill" : "play.fill")
            
            Image(systemName: iconName)
                .font(.system(size: size * 0.35, weight: .semibold))
                .foregroundStyle(.primary)
                .contentTransition(.symbolEffect(.replace, options: .speed(1.3)))
        }
    }
    
    @ViewBuilder
    private var detailContent: some View {
        if isCompleted && !isExceeded {
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(habit.actualColor.gradient)
                .transition(.symbolEffect(.drawOn))
        } else {
            Text(getProgressText())
                .font(.system(size: size * 0.2, weight: .bold))
                .transition(.scale.combined(with: .opacity))
        }
    }

    private func getProgressText() -> String {
        let value = Int(currentValue) ?? 0
        switch habit.type {
        case .count: return "\(value)"
        case .time: return value.formattedAsTime()
        }
    }
}
