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
                        // ✅ Центрируем иконку по вертикали
                        VStack {
                            Spacer()
                            LiveActivityHabitIcon(context: context, size: 32)
                                .frame(width: 36, height: 36)
                            Spacer()
                        }
                        .padding(.leading, 8)
                    }
                
                DynamicIslandExpandedRegion(.center) {
                        // ✅ Центрируем весь контент по вертикали
                        VStack {
                            Spacer()
                            
                            VStack(spacing: 3) {
                                // Habit Name
                                Text(context.attributes.habitName)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity)
                                
                                // Goal
                                Text("goal".localized(with: context.attributes.habitGoal.formattedAsLocalizedDuration()))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    
                                // Timer with stable overlay
                                if context.state.isTimerRunning, let startTime = context.state.timerStartTime {
                                    let baseProgress = context.state.currentProgress
                                    let adjustedStartTime = startTime.addingTimeInterval(-TimeInterval(baseProgress))
                                    
                                    Text("99:99:99")
                                        .font(.system(.largeTitle, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundColor(.clear)  // Прозрачный шаблон
                                        .monospacedDigit()
                                        .overlay(alignment: .center) {
                                            Text(timerInterval: adjustedStartTime...Date.distantFuture, countsDown: false)
                                                .font(.system(.title3, design: .rounded))
                                                .fontWeight(.bold)
                                                .foregroundStyle(.primary)
                                                .monospacedDigit()
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                        }
                                } else {
                                    let currentProgress = context.state.currentProgress
                                    
                                    // ✅ Статический с таким же overlay для консистентности
                                    Text("99:99:99")
                                        .font(.system(.largeTitle, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundColor(.clear)
                                        .monospacedDigit()
                                        .overlay(alignment: .center) {
                                            Text(currentProgress.formattedAsTime())
                                                .font(.system(.title3, design: .rounded))
                                                .fontWeight(.bold)
                                                .foregroundStyle(.primary)
                                                .monospacedDigit()
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                        }
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    
                    DynamicIslandExpandedRegion(.trailing) {
                        // ✅ Центрируем Progress Ring по вертикали
                        VStack {
                            Spacer()
                            LiveActivityProgressRing(context: context)
                            Spacer()
                        }
                        .padding(.trailing, 8)
                    }
                    
                    DynamicIslandExpandedRegion(.bottom) {
                        Color.clear.frame(height: 0)
                    }
            } compactLeading: {
                LiveActivityHabitIcon(context: context, size: 16)
            } compactTrailing: {
                TimerDisplayView(context: context)
            } minimal: {
                LiveActivityHabitIcon(context: context, size: 14)
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
        return context.attributes.habitGoal.formattedAsLocalizedDuration()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // ✅ Left: Habit icon (как в HabitCardView)
            LiveActivityHabitIcon(context: context, size: 36)
                .frame(width: 45, height: 45)
            
            // ✅ Middle: Title and progress/goal (как в HabitCardView)
            VStack(alignment: .leading, spacing: 3) {
                Text(context.attributes.habitName)
                    .font(.headline.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)
                
                // Goal
                Text("goal".localized(with: formattedGoal))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
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
                        .monospacedDigit()
                }
                
                
            }
            
            Spacer()
            
            // ✅ Right: Progress Ring (обновленный)
            LiveActivityProgressRing(context: context)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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
    
    // ✅ Ring colors
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

// MARK: - Dynamic Island Components
struct HabitInfoView: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    
    @Environment(\.colorScheme) private var colorScheme
    
    // ✅ Вычисляем текущий прогресс (как в CompactLiveActivityContent)
    private var currentProgress: Int {
        if context.state.isTimerRunning, let startTime = context.state.timerStartTime {
            let elapsed = Int(Date().timeIntervalSince(startTime))
            return context.state.currentProgress + elapsed
        } else {
            return context.state.currentProgress
        }
    }
    
    private var formattedProgress: String {
        return currentProgress.formattedAsTime()
    }
    
    private var formattedGoal: String {
        return context.attributes.habitGoal.formattedAsLocalizedDuration()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            LiveActivityHabitIcon(context: context, size: 32)
                .frame(width: 44, height: 44)  // Компактнее для Expanded
            
            // ✅ Middle: Title and progress/goal (ИДЕНТИЧНО!)
            VStack(alignment: .leading, spacing: 3) {
                Text(context.attributes.habitName)
                    .font(.subheadline.weight(.semibold))  // Чуть меньше чем в Compact
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)
                
                // Goal
                Text("goal".localized(with: formattedGoal))
                    .font(.caption)  // Меньше чем в Compact
                    .foregroundStyle(.secondary)
                
                if context.state.isTimerRunning, let startTime = context.state.timerStartTime {
                    let baseProgress = context.state.currentProgress
                    let adjustedStartTime = startTime.addingTimeInterval(-TimeInterval(baseProgress))
                    
                    Text(timerInterval: adjustedStartTime...Date.distantFuture, countsDown: false)
                        .font(.system(.headline, design: .rounded))  // Меньше чем title2
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                } else {
                    Text(formattedProgress)
                        .font(.system(.headline, design: .rounded))  // Меньше чем title2
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)  // Меньше padding чем в Compact
        .padding(.vertical, 6)
    }
}

struct TimerDisplayView: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    
    private var templateText: String {
            let current = context.state.currentProgress
            if current >= 3600 {
                return "9:99:99"
            } else {
                return "99:99"
            }
        }
    
    var body: some View {
        if context.state.isTimerRunning, let startTime = context.state.timerStartTime {
            let baseProgress = context.state.currentProgress
            let adjustedStartTime = startTime.addingTimeInterval(-TimeInterval(baseProgress))
            
            Text(templateText)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.clear)
                .monospacedDigit()
                .overlay(alignment: .leading) {
                    Text(timerInterval: adjustedStartTime...Date.distantFuture, countsDown: false)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
        } else {
            Text(templateText)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.clear)
                .monospacedDigit()
                .overlay(alignment: .leading) {
                    Text(context.state.currentProgress.formattedAsTime())
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
        }
    }
}
