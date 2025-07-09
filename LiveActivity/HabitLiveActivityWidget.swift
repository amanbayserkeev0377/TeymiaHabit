import ActivityKit
import WidgetKit
import SwiftUI

struct HabitLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HabitActivityAttributes.self) { context in
            CompactLiveActivityContent(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HabitInfoView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ControlsView(context: context)
                }
            } compactLeading: {
                TimerDisplayView(context: context)
            } compactTrailing: {
                Image(systemName: context.state.isTimerRunning ? "play.fill" : "pause.fill")
                    .foregroundStyle(context.attributes.habitIconColor.color)
            } minimal: {
                Image(systemName: context.state.isTimerRunning ? "play.fill" : "pause.fill")
                    .foregroundStyle(context.attributes.habitIconColor.color)
            }
        }
    }
}

// MARK: - Compact Live Activity Content
struct CompactLiveActivityContent: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                // Left: Habit icon
                Image(systemName: context.attributes.habitIcon)
                    .font(.system(size: 26))
                    .foregroundStyle(context.attributes.habitIconColor.adaptiveGradient(for: colorScheme))
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(context.attributes.habitIconColor.adaptiveGradient(for: colorScheme).opacity(0.2))
                    )
                
                // Center: Timer display
                VStack(alignment: .leading, spacing: 2) {
                    TimerDisplayView(context: context)
                    
                    Text("goal_format".localized(with: context.attributes.habitGoal.formattedAsDuration()))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Right: Control buttons
            HStack(spacing: 8) {
                // Play/Pause button
                Button(intent: StopTimerIntent(habitId: context.attributes.habitId)) {
                    Image(systemName: context.state.isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(context.attributes.habitIconColor.adaptiveGradient(for: colorScheme))
                        .frame(width: 52, height: 52)
                        .background(
                            Circle()
                                .fill(context.attributes.habitIconColor.adaptiveGradient(for: colorScheme).opacity(0.2))
                        )
                        .contentShape(Circle())
                }
                .buttonStyle(LiveActivityButtonStyle())

                // Dismiss button
                Button(intent: DismissActivityIntent(habitId: context.attributes.habitId)) {
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color(.systemGray))
                        .frame(width: 52, height: 52)
                        .background(
                            Circle()
                                .fill(Color(.systemGray5))
                        )
                        .contentShape(Circle())
                }
                .buttonStyle(LiveActivityButtonStyle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}

// MARK: - Dynamic Island Components
struct HabitInfoView: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(context.attributes.habitName)
                .font(.caption)
                .fontWeight(.medium)
            Text("goal_format".localized(with: context.attributes.habitGoal.formattedAsDuration()))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct TimerView: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    
    var body: some View {
        VStack(alignment: .trailing) {
            TimerDisplayView(context: context)
                .foregroundColor(context.attributes.habitIconColor.color)
        }
    }
}

struct ControlsView: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Button(intent: StopTimerIntent(habitId: context.attributes.habitId)) {
                Image(systemName: context.state.isTimerRunning ? "pause.fill" : "play.fill")
            }
            .buttonStyle(.bordered)
            .tint(context.attributes.habitIconColor.color)
            
            Spacer()
            
            Button(intent: DismissActivityIntent(habitId: context.attributes.habitId)) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
        }
    }
}

struct LiveActivityButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.75 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.8), value: configuration.isPressed)
    }
}

// ✅ КАСТОМНЫЙ ТАЙМЕР КОМПОНЕНТ - Точно такая же логика как в приложении!
struct TimerDisplayView: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    
    var body: some View {
        VStack {
            if context.state.isTimerRunning, let startTime = context.state.timerStartTime {
                // Корректируем начальное время с учетом currentProgress
                let adjustedStartTime = startTime.addingTimeInterval(-TimeInterval(context.state.currentProgress))
                Text(adjustedStartTime, style: .timer)
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .background(Color.green.opacity(0.3)) // Для отладки
            } else {
                // Отображаем статический прогресс, когда таймер остановлен
                Text(context.state.currentProgress.formattedAsTime())
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .background(Color.green.opacity(0.3)) // Для отладки
            }
        }
        .onAppear {
            print("🎬 Live Activity TimerDisplay appeared")
            print("🔍 Context: running=\(context.state.isTimerRunning), progress=\(context.state.currentProgress), startTime=\(String(describing: context.state.timerStartTime))")
        }
    }
}
