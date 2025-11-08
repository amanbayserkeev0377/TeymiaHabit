import SwiftUI

enum ProgressRingStyle {
    case detail
    case compact
}

struct ProgressRing: View {
    let progress: Double
    let currentValue: String
    let isCompleted: Bool
    let isExceeded: Bool
    let habit: Habit?
    let style: ProgressRingStyle
    
    var size: CGFloat = 180
    var lineWidth: CGFloat? = nil
    var fontSize: CGFloat? = nil
    var iconSize: CGFloat? = nil
    
    @State private var animateCheckmark = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var ringColors: [Color] {
        AppColorManager.shared.getRingColors(
            for: habit,
            isCompleted: isCompleted,
            isExceeded: isExceeded,
            colorScheme: colorScheme
        )
    }
    
    private var completedTextGradient: AnyShapeStyle {
        AppColorManager.getCompletedBarStyle(for: colorScheme)
    }
    
    private var exceededTextGradient: AnyShapeStyle {
        AppColorManager.getExceededBarStyle(for: colorScheme)
    }
    
    private var adaptiveLineWidth: CGFloat {
        lineWidth ?? (size * 0.11)
    }
    
    private var adaptedFontSize: CGFloat {
        if let customFontSize = fontSize {
            return customFontSize
        }
        return size * 0.20
    }
    
    private var adaptedIconSize: CGFloat {
        iconSize ?? (size * 0.4)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.1), lineWidth: adaptiveLineWidth)
            
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    LinearGradient(
                        colors: ringColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: adaptiveLineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            if style == .detail {
                ZStack {
                    if isCompleted && !isExceeded {
                        Image(systemName: "checkmark")
                            .font(.system(size: adaptedIconSize, weight: .bold))
                            .foregroundStyle(completedTextGradient)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    if isExceeded {
                        Group {
                            if let habit = habit {
                                Text(getProgressText(for: habit))
                                    .font(.system(size: adaptedFontSize, weight: .bold))
                                    .foregroundStyle(exceededTextGradient)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                            } else {
                                Text(currentValue)
                                    .font(.system(size: adaptedFontSize, weight: .bold))
                                    .foregroundStyle(exceededTextGradient)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    if !isCompleted {
                        Group {
                            if let habit = habit {
                                Text(getProgressText(for: habit))
                                    .font(.system(size: adaptedFontSize, weight: .bold))
                                    .foregroundStyle(.primary)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                            } else {
                                Text(currentValue)
                                    .font(.system(size: adaptedFontSize, weight: .bold))
                                    .foregroundStyle(.primary)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: isCompleted)
                .animation(.easeInOut(duration: 0.4), value: isExceeded)
            } else if style == .compact {
                ZStack {
                    /// Gray checkmark base (visible when not completed)
                    Image(systemName: "checkmark")
                        .font(.system(size: adaptedIconSize, weight: .bold))
                        .foregroundStyle(AnyShapeStyle(Color.secondary.opacity(0.3)))
                        .scaleEffect(!isCompleted && !isExceeded ? 1.0 : 0.0)
                        .opacity(!isCompleted && !isExceeded ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.4).delay(0.2), value: isCompleted)
                        .animation(.easeInOut(duration: 0.4).delay(0.2), value: isExceeded)
                    
                    /// Colored checkmark (appears when completed/exceeded)
                    Image(systemName: "checkmark")
                        .font(.system(size: adaptedIconSize, weight: .bold))
                        .foregroundStyle(
                            isExceeded ? exceededTextGradient : completedTextGradient
                        )
                        .scaleEffect(isCompleted || isExceeded ? 1.0 : 0.0)
                        .opacity(isCompleted || isExceeded ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.4).delay(0.2), value: isCompleted)
                        .animation(.easeInOut(duration: 0.4).delay(0.2), value: isExceeded)
                }
            }
        }
        .frame(width: size, height: size)
    }
    
    // MARK: - Helper Methods
    
    private func getProgressText(for habit: Habit) -> String {
        let progress = Int(currentValue) ?? 0
        
        switch habit.type {
        case .count:
            return "\(progress)"
        case .time:
            return progress.formattedAsTime()
        }
    }
}

// MARK: - Convenience Initializers

extension ProgressRing {
    static func detail(
        progress: Double,
        currentProgress: Int,
        goal: Int,
        habitType: HabitType,
        isCompleted: Bool,
        isExceeded: Bool,
        habit: Habit?,
        size: CGFloat = 180,
        lineWidth: CGFloat? = nil,
        fontSize: CGFloat? = nil,
        iconSize: CGFloat? = nil
    ) -> ProgressRing {
        ProgressRing(
            progress: progress,
            currentValue: "\(currentProgress)",
            isCompleted: isCompleted,
            isExceeded: isExceeded,
            habit: habit,
            style: .detail,
            size: size,
            lineWidth: lineWidth,
            fontSize: fontSize,
            iconSize: iconSize
        )
    }
    
    static func compact(
        progress: Double,
        isCompleted: Bool,
        isExceeded: Bool,
        habit: Habit?,
        size: CGFloat = 52,
        lineWidth: CGFloat? = nil
    ) -> ProgressRing {
        ProgressRing(
            progress: progress,
            currentValue: "",
            isCompleted: isCompleted,
            isExceeded: isExceeded,
            habit: habit,
            style: .compact,
            size: size,
            lineWidth: lineWidth
        )
    }
}

// MARK: - Interactive Compact Ring

extension ProgressRing {
    /// Interactive compact ring with play/pause or plus icon inside
    static func compactInteractive(
        progress: Double,
        isCompleted: Bool,
        isExceeded: Bool,
        habit: Habit?,
        isTimerRunning: Bool = false,
        size: CGFloat = 52,
        lineWidth: CGFloat? = nil
    ) -> some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.secondary.opacity(0.1), lineWidth: lineWidth ?? (size * 0.11))
            
            // Progress circle
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    LinearGradient(
                        colors: AppColorManager.shared.getRingColors(
                            for: habit,
                            isCompleted: isCompleted,
                            isExceeded: isExceeded,
                            colorScheme: .light
                        ),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth ?? (size * 0.11),
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Interactive icon inside
            Group {
                if let habitType = habit?.type {
                    switch habitType {
                    case .count:
                        // Plus icon for count habits
                        Image(systemName: "plus")
                            .font(.system(size: size * 0.35, weight: .semibold))
                            .foregroundStyle(Color.primary)
                        
                    case .time:
                        // Play/Pause for time habits (from Assets)
                        Image(isTimerRunning ? "pause.fill" : "play.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: size * 0.3, height: size * 0.3)
                            .foregroundStyle(Color.primary)
                    }
                }
            }
        }
        .frame(width: size, height: size)
    }
}
