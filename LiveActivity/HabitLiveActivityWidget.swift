import ActivityKit
import WidgetKit
import SwiftUI

struct HabitLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HabitActivityAttributes.self) { context in
            CompactLiveActivityView(context: context)
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
                // Native iOS timer that automatically updates - shows total time
                if context.state.isTimerRunning, let startTime = context.state.timerStartTime {
                    let adjustedStartTime = startTime.addingTimeInterval(-TimeInterval(context.state.currentProgress))
                    Text(adjustedStartTime, style: .timer)
                        .font(.title2)
                        .fontWeight(.semibold)
                } else {
                    Text(context.state.currentProgress.formattedAsTime())
                        .font(.title2)
                        .fontWeight(.semibold)
                }
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

// MARK: - Compact Notification-Style View
struct CompactLiveActivityView: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    
    var body: some View {
        // Only use TimelineView for percentage calculations, not for timer display
        TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
            CompactLiveActivityContent(context: context, currentTime: timeline.date)
        }
    }
}

// MARK: - Compact Live Activity Content
struct CompactLiveActivityContent: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    let currentTime: Date
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // ИСПРАВЛЕНО: убираем обертку Button для deep linking, чтобы не блокировать кнопки управления
            HStack(spacing: 12) {
                // Left: Real habit icon (НЕ кнопка, просто иконка)
                Image(systemName: context.attributes.habitIcon)
                    .font(.system(size: 26))
                    .foregroundStyle(context.attributes.habitIconColor.adaptiveGradient(for: colorScheme))
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(context.attributes.habitIconColor.adaptiveGradient(for: colorScheme).opacity(0.2))
                    )
                
                // Center: Live time (НЕ кнопка, просто текст)
                VStack(alignment: .leading, spacing: 2) {
                    if context.state.isTimerRunning, let startTime = context.state.timerStartTime {
                        let adjustedStartTime = startTime.addingTimeInterval(-TimeInterval(context.state.currentProgress))
                        Text(adjustedStartTime, style: .timer)
                            .font(.system(.title2, weight: .semibold))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    } else {
                        Text(context.state.currentProgress.formattedAsTime())
                            .font(.system(.title2, weight: .semibold))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 4) {
                        Text("goal_format".localized(with: context.attributes.habitGoal.formattedAsGoal()))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            // ДОБАВЛЕНО: Если нужен deep linking, добавим позже через отдельную невидимую кнопку
            
            Spacer()
            
            // Right: Control buttons - теперь НЕ заблокированы
            HStack(spacing: 8) {
                // Play/Pause button - uses habit color with adaptive gradient
                Button(intent: StopTimerIntent(habitId: context.attributes.habitId)) {
                    Image(systemName: context.state.isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(context.attributes.habitIconColor.adaptiveGradient(for: colorScheme))
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(context.attributes.habitIconColor.adaptiveGradient(for: colorScheme).opacity(0.2))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Dismiss button - neutral color
                Button(intent: DismissActivityIntent(habitId: context.attributes.habitId)) {
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color(.systemGray))
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(Color(.systemGray5))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}

// MARK: - Dynamic Island Components (unchanged)
struct HabitInfoView: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(context.attributes.habitName)
                .font(.caption)
                .fontWeight(.medium)
            Text("goal_format".localized(with: context.attributes.habitGoal.formattedAsGoal()))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct TimerView: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    
    var body: some View {
        VStack(alignment: .trailing) {
            LiveTimerText(context: context)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(context.attributes.habitIconColor.color)
        }
    }
}

// MARK: - Live Timer Text Component with Native Date Formatting
struct LiveTimerText: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    
    var body: some View {
        if context.state.isTimerRunning, let startTime = context.state.timerStartTime {
            // Calculate adjusted start time to show total progress
            let adjustedStartTime = startTime.addingTimeInterval(-TimeInterval(context.state.currentProgress))
            
            // Use native iOS timer formatting that updates automatically
            Text(adjustedStartTime, style: .timer)
                .onAppear {
                    print("🔥 Native timer started - Total time display")
                }
        } else {
            Text(context.state.currentProgress.formattedAsTime())
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

// MARK: - Goal Formatting Extension
extension Int {
    func formattedAsGoal() -> String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        
        if hours > 0 {
            if minutes > 0 {
                return "hours_minutes_format".localized(with: hours, minutes)
            } else {
                return "hours_format".localized(with: hours)
            }
        } else {
            return "minutes_format".localized(with: minutes)
        }
    }
}
