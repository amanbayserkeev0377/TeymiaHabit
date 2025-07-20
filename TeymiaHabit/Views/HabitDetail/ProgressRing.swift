import SwiftUI

enum ProgressRingStyle {
    case detail    // Прогресс внутри кольца (для HabitDetailView)
    case compact   // Пустое кольцо (для HomeView)
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
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var ringColors: [Color] {
        return AppColorManager.shared.getRingColors(
            for: habit,
            isCompleted: isCompleted,
            isExceeded: isExceeded,
            colorScheme: colorScheme
        )
    }
    
    private var completedTextGradient: AnyShapeStyle {
        return AppColorManager.getCompletedBarStyle(for: colorScheme)
    }
    
    private var exceededTextGradient: AnyShapeStyle {
        return AppColorManager.getExceededBarStyle(for: colorScheme)
    }
    
    private var adaptiveLineWidth: CGFloat {
        return lineWidth ?? (size * 0.11)
    }
    
    private var adaptedFontSize: CGFloat {
        if let customFontSize = fontSize {
            return customFontSize
        }
        
        return size * 0.20
    }
    
    private var adaptedIconSize: CGFloat {
        return iconSize ?? (size * 0.4)
    }
    
    var body: some View {
        ZStack {
            // Фоновый круг
            Circle()
                .stroke(Color.secondary.opacity(0.1), lineWidth: adaptiveLineWidth)
            
            // Прогресс круг
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
                .animation(.easeInOut(duration: 0.3), value: progress)
            
            // Показываем checkmark для обоих стилей
            if style == .detail {
                if isCompleted && !isExceeded {
                    // Completed checkmark - градиент как кольцо
                    Image(systemName: "checkmark")
                        .font(.system(size: adaptedIconSize, weight: .bold))
                        .foregroundStyle(completedTextGradient)
                } else if isExceeded {
                    // Exceeded text - градиент как кольцо
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
                } else {
                    // In progress - градиент привычки
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
            } else if style == .compact {
                // Compact style - только checkmark
                Image(systemName: "checkmark")
                    .font(.system(size: adaptedIconSize, weight: .bold))
                    .foregroundStyle(
                        isExceeded ? exceededTextGradient :
                        isCompleted ? completedTextGradient :
                        AnyShapeStyle(Color.secondary.opacity(0.3))
                    )
            }
        }
        .frame(width: size, height: size)
    }
    
    // MARK: - Helper Methods
    
    private func getProgressText(for habit: Habit) -> String {
        // Получаем прогресс из currentValue
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
    
    // Для HabitDetailView - с текстом внутри "прогресс/цель"
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
        
        return ProgressRing(
            progress: progress,
            currentValue: "\(currentProgress)", // Передаем только прогресс
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
    
    // Для HomeView - пустое кольцо
    static func compact(
        progress: Double,
        isCompleted: Bool,
        isExceeded: Bool,
        habit: Habit?,
        size: CGFloat = 60,
        lineWidth: CGFloat? = nil
    ) -> ProgressRing {
        return ProgressRing(
            progress: progress,
            currentValue: "", // Не используется
            isCompleted: isCompleted,
            isExceeded: isExceeded,
            habit: habit,
            style: .compact,
            size: size,
            lineWidth: lineWidth
        )
    }
}
