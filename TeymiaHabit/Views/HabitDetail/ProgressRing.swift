import SwiftUI

struct ProgressRing: View {
    let progress: Double
    let currentValue: String
    let isCompleted: Bool
    let isExceeded: Bool
    let habit: Habit?
    
    var size: CGFloat = 180
    var lineWidth: CGFloat? = nil
    var fontSize: CGFloat? = nil
    var iconSize: CGFloat? = nil
    
    private var ringColor: Color {
        if isCompleted || isExceeded {
            return .green
        } else {
            return habit?.iconColor.color ?? .orange
        }
    }
    
    private var completedTextGradient: AnyShapeStyle {
        AnyShapeStyle(Color.green.gradient)
    }
    
    private var adaptiveLineWidth: CGFloat {
        lineWidth ?? (size * 0.11)
    }
    
    private var adaptedFontSize: CGFloat {
        if let customFontSize = fontSize {
            return customFontSize
        }
        return size * 0.25
    }
    
    private var adaptedIconSize: CGFloat {
        iconSize ?? (size * 0.5)
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.secondary.opacity(0.1), lineWidth: adaptiveLineWidth)
            
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    ringColor.gradient,
                    style: StrokeStyle(
                        lineWidth: adaptiveLineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)
            
            // Content inside ring
            ZStack {
                // Completed checkmark (not exceeded)
                if isCompleted && !isExceeded {
                    Image("check")
                        .resizable()
                        .frame(width: adaptedIconSize, height: adaptedIconSize)
                        .foregroundStyle(completedTextGradient)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Exceeded - show progress text
                if isExceeded {
                    Group {
                        if let habit = habit {
                            Text(getProgressText(for: habit))
                                .font(.system(size: adaptedFontSize, weight: .bold))
                                .fontDesign(.rounded)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        } else {
                            Text(currentValue)
                                .font(.system(size: adaptedFontSize, weight: .bold))
                                .fontDesign(.rounded)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // In progress - show progress text
                if !isCompleted {
                    Group {
                        if let habit = habit {
                            Text(getProgressText(for: habit))
                                .font(.system(size: adaptedFontSize, weight: .bold))
                                .fontDesign(.rounded)
                                .foregroundStyle(.primary)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        } else {
                            Text(currentValue)
                                .font(.system(size: adaptedFontSize, weight: .bold))
                                .fontDesign(.rounded)
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
    /// Create a detail progress ring (large, with numbers/checkmark)
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
            size: size,
            lineWidth: lineWidth,
            fontSize: fontSize,
            iconSize: iconSize
        )
    }
    
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
        let ringColor: Color = {
            if isCompleted || isExceeded {
                return .green
            } else {
                return habit?.iconColor.color ?? .blue
            }
        }()
        
        let effectiveLineWidth = lineWidth ?? (size * 0.11)
        
        return ZStack {
            // Background circle
            Circle()
                .stroke(Color.secondary.opacity(0.1), lineWidth: effectiveLineWidth)
            
            // Progress circle - simple and clean
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    ringColor.gradient,
                    style: StrokeStyle(
                        lineWidth: effectiveLineWidth,
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
                        Image(systemName: "plus")
                            .font(.system(size: size * 0.35))
                            .foregroundStyle(Color.primary)
                        
                    case .time:
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
