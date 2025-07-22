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
    
    // ✅ Простое локальное состояние только для анимации
    @State private var animateCheckmark = false
    
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
            
            // Прогресс круг - ТОЛЬКО анимация заполнения кольца
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
            
            // Контент внутри кольца
            if style == .detail {
                ZStack {
                    // ✅ Галочка для completed (но не exceeded)
                    if isCompleted && !isExceeded {
                        Image(systemName: "checkmark")
                            .font(.system(size: adaptedIconSize, weight: .bold))
                            .foregroundStyle(completedTextGradient)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // ✅ Exceeded text
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
                    
                    // ✅ In progress text
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
                // ✅ Плавные переходы между состояниями с scale эффектом
                .animation(.easeInOut(duration: 0.4), value: isCompleted)
                .animation(.easeInOut(duration: 0.4), value: isExceeded)
            } else if style == .compact {
                // ✅ Всегда показываем серую галочку как основу
                ZStack {
                    // Серая галочка (всегда видна при < 100%)
                    Image(systemName: "checkmark")
                        .font(.system(size: adaptedIconSize, weight: .bold))
                        .foregroundStyle(AnyShapeStyle(Color.secondary.opacity(0.3)))
                        .scaleEffect(!isCompleted && !isExceeded ? 1.0 : 0.0)
                        .opacity(!isCompleted && !isExceeded ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.4).delay(0.2), value: isCompleted)
                        .animation(.easeInOut(duration: 0.4).delay(0.2), value: isExceeded)
                    
                    // Цветная галочка (появляется при completed/exceeded)
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
    
    // Для HomeView - пустое кольцо
    static func compact(
        progress: Double,
        isCompleted: Bool,
        isExceeded: Bool,
        habit: Habit?,
        size: CGFloat = 52,
        lineWidth: CGFloat? = nil
    ) -> ProgressRing {
        return ProgressRing(
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
