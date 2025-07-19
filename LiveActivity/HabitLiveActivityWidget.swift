import ActivityKit
import WidgetKit
import SwiftUI

struct HabitLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HabitActivityAttributes.self) { context in
            CompactLiveActivityContent(context: context)
            // ✅ DEEPLINK: По тапу на всю Live Activity открывается конкретная привычка
                .widgetURL(URL(string: "teymiahabit://habit/\(context.attributes.habitId)"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HabitInfoView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    LiveActivityProgressRing(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // ✅ Можно показать дополнительную информацию или оставить пустым
                    HStack {
                        Text("Goal: \(context.attributes.habitGoal.formattedAsTime())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        // Или можно вообще убрать этот блок если не нужен
                    }
                }
            } compactLeading: {
                TimerDisplayView(context: context)
            } compactTrailing: {
                // ✅ Используем habitIcon extension
                context.habitIcon(size: 16)
            } minimal: {
                // ✅ Используем habitIcon extension
                context.habitIcon(size: 16)
            }
            // ✅ DEEPLINK и для Dynamic Island
            .widgetURL(URL(string: "teymiahabit://habit/\(context.attributes.habitId)"))
        }
    }
}

// MARK: - Compact Live Activity Content (УПРОЩЕННЫЙ ДИЗАЙН)
struct CompactLiveActivityContent: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    
    @Environment(\.colorScheme) private var colorScheme
    
    // ✅ Вычисляем текущий прогресс
    private var currentProgress: Int {
        if context.state.isTimerRunning, let startTime = context.state.timerStartTime {
            let elapsed = Int(Date().timeIntervalSince(startTime))
            return context.state.currentProgress + elapsed
        } else {
            return context.state.currentProgress
        }
    }
    
    private var isCompleted: Bool {
        return currentProgress >= context.attributes.habitGoal
    }
    
    private var isExceeded: Bool {
        return currentProgress > context.attributes.habitGoal
    }
    
    // ✅ Градиенты как в HabitCardView
    private var completedTextGradient: AnyShapeStyle {
        let topColor = colorScheme == .dark ?
        Color(#colorLiteral(red: 0.2, green: 0.55, blue: 0.05, alpha: 1)) : // completedDarkGreen
        Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.3, alpha: 1))    // completedLightGreen
        let bottomColor = colorScheme == .dark ?
        Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.3, alpha: 1)) :  // completedLightGreen
        Color(#colorLiteral(red: 0.2, green: 0.55, blue: 0.05, alpha: 1))   // completedDarkGreen
        
        return AnyShapeStyle(
            LinearGradient(
                colors: [topColor, bottomColor],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var exceededTextGradient: AnyShapeStyle {
        let topColor = colorScheme == .dark ?
        Color(#colorLiteral(red: 0.2, green: 0.55, blue: 0.05, alpha: 1)) : // exceededDarkGreen
        Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.9, alpha: 1))     // exceededLightMint
        let bottomColor = colorScheme == .dark ?
        Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.9, alpha: 1)) :  // exceededLightMint
        Color(#colorLiteral(red: 0.2, green: 0.55, blue: 0.05, alpha: 1))   // exceededDarkGreen
        
        return AnyShapeStyle(
            LinearGradient(
                colors: [topColor, bottomColor],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // ✅ Форматированный прогресс и цель
    private var formattedProgress: String {
        return currentProgress.formattedAsTime()
    }
    
    private var formattedGoal: String {
        return context.attributes.habitGoal.formattedAsTime()
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // ✅ Left: Habit icon (как в HabitCardView)
            context.habitIcon(size: 30)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(context.attributes.habitIconColor.adaptiveGradient(for: colorScheme).opacity(0.15))
                )
            
            // ✅ Middle: Title and progress/goal (как в HabitCardView)
            VStack(alignment: .leading, spacing: 5) {
                if context.state.isTimerRunning, let startTime = context.state.timerStartTime {
                    let baseProgress = context.state.currentProgress
                    let adjustedStartTime = startTime.addingTimeInterval(-TimeInterval(baseProgress))
                    
                    Text(timerInterval: adjustedStartTime...Date.distantFuture, countsDown: false)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                } else {
                    Text(formattedProgress)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
                
                // Goal
                Text("goal".localized(with: formattedGoal))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // ✅ Right: Progress Ring (обновленный)
            LiveActivityProgressRing(context: context)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}

// MARK: - Live Activity Progress Ring
struct LiveActivityProgressRing: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let ringSize: CGFloat = 58
    private let lineWidth: CGFloat = 7
    
    // ✅ Вычисляем текущий прогресс
    private var currentProgress: Int {
        if context.state.isTimerRunning, let startTime = context.state.timerStartTime {
            let elapsed = Int(Date().timeIntervalSince(startTime))
            return context.state.currentProgress + elapsed
        } else {
            return context.state.currentProgress
        }
    }
    
    private var completionPercentage: Double {
        guard context.attributes.habitGoal > 0 else { return 0 }
        return Double(currentProgress) / Double(context.attributes.habitGoal)
    }
    
    private var isCompleted: Bool {
        return currentProgress >= context.attributes.habitGoal
    }
    
    private var isExceeded: Bool {
        return currentProgress > context.attributes.habitGoal
    }
    
    // ✅ Градиенты как в основном приложении
    private var completedTextGradient: AnyShapeStyle {
        let topColor = colorScheme == .dark ?
        Color(#colorLiteral(red: 0.2, green: 0.55, blue: 0.05, alpha: 1)) : // completedDarkGreen
        Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.3, alpha: 1))    // completedLightGreen
        let bottomColor = colorScheme == .dark ?
        Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.3, alpha: 1)) :  // completedLightGreen
        Color(#colorLiteral(red: 0.2, green: 0.55, blue: 0.05, alpha: 1))   // completedDarkGreen
        
        return AnyShapeStyle(
            LinearGradient(
                colors: [topColor, bottomColor],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var exceededTextGradient: AnyShapeStyle {
        let topColor = colorScheme == .dark ?
        Color(#colorLiteral(red: 0.2, green: 0.55, blue: 0.05, alpha: 1)) : // exceededDarkGreen
        Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.9, alpha: 1))     // exceededLightMint
        let bottomColor = colorScheme == .dark ?
        Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.9, alpha: 1)) :  // exceededLightMint
        Color(#colorLiteral(red: 0.2, green: 0.55, blue: 0.05, alpha: 1))   // exceededDarkGreen
        
        return AnyShapeStyle(
            LinearGradient(
                colors: [topColor, bottomColor],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // ✅ Ring colors (simplified без AppColorManager)
    private var ringColors: [Color] {
        if isExceeded {
            let lightMint = Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.9, alpha: 1))
            let darkGreen = Color(#colorLiteral(red: 0.2, green: 0.55, blue: 0.05, alpha: 1))
            
            let visualTop = colorScheme == .dark ? darkGreen : lightMint
            let visualBottom = colorScheme == .dark ? lightMint : darkGreen
            
            return [visualBottom, visualTop] // Converted for -90° rotation
        } else if isCompleted {
            let lightGreen = Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.3, alpha: 1))
            let darkGreen = Color(#colorLiteral(red: 0.2, green: 0.55, blue: 0.05, alpha: 1))
            
            let visualTop = colorScheme == .dark ? darkGreen : lightGreen
            let visualBottom = colorScheme == .dark ? lightGreen : darkGreen
            
            return [visualBottom, visualTop] // Converted for -90° rotation
        } else {
            // Use habit color gradient
            let habitColor = context.attributes.habitIconColor
            let lightColor = habitColor.lightColor
            let darkColor = habitColor.darkColor
            
            let visualTop = colorScheme == .dark ? darkColor : lightColor
            let visualBottom = colorScheme == .dark ? lightColor : darkColor
            
            return [visualBottom, visualTop] // Converted for -90° rotation
        }
    }
    
    private var adaptedIconSize: CGFloat {
        return ringSize * 0.4
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.secondary.opacity(0.1), lineWidth: lineWidth)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: min(completionPercentage, 1.0))
                .stroke(
                    LinearGradient(
                        colors: ringColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: completionPercentage)
            
            // ✅ Checkmark как в compact ProgressRing
            Image(systemName: "checkmark")
                .font(.system(size: adaptedIconSize, weight: .bold))
                .foregroundStyle(
                    isExceeded ? exceededTextGradient :
                        isCompleted ? completedTextGradient :
                        AnyShapeStyle(Color.secondary.opacity(0.3))
                )
        }
        .frame(width: ringSize, height: ringSize)
    }
}

// MARK: - Dynamic Island Components (обновленные)
struct HabitInfoView: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(context.attributes.habitName)
                .font(.caption)
                .fontWeight(.medium)
            Text("goal_format".localized(with: context.attributes.habitGoal.formattedAsTime()))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct TimerDisplayView: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    
    var body: some View {
        VStack {
            if context.state.isTimerRunning, let startTime = context.state.timerStartTime {
                let baseProgress = context.state.currentProgress
                // ✅ Создаем "виртуальное" время начала для правильного отображения
                let adjustedStartTime = startTime.addingTimeInterval(-TimeInterval(baseProgress))
                
                // ✅ Нативный таймер: обновляется автоматически каждую секунду
                Text(timerInterval: adjustedStartTime...Date.distantFuture, countsDown: false)
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .monospacedDigit()
            } else {
                // ✅ Статический прогресс
                Text(context.state.currentProgress.formattedAsTime())
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .monospacedDigit()
            }
        }
    }
}
