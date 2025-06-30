import ActivityKit
import WidgetKit
import SwiftUI

struct HabitLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HabitActivityAttributes.self) { context in
            LockScreenView(context: context)
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
                Text(context.state.formattedTime)
                    .font(.caption2)
                    .fontWeight(.semibold)
            } compactTrailing: {
                Image(systemName: context.state.isTimerRunning ? "play.fill" : "pause.fill")
                    .foregroundColor(context.state.isTimerRunning ? .green : .orange)
            } minimal: {
                Image(systemName: context.state.isTimerRunning ? "play.fill" : "pause.fill")
                    .foregroundColor(context.state.isTimerRunning ? .green : .orange)
            }
        }
    }
}

// UI Components
struct LockScreenView: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(context.attributes.habitName)
                        .font(.headline)
                    Text(context.state.formattedTime)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                Spacer()
                
                Image(systemName: context.state.isTimerRunning ? "play.circle.fill" : "pause.circle.fill")
                    .foregroundColor(context.state.isTimerRunning ? .green : .orange)
                    .font(.title)
            }
            
            HStack(spacing: 12) {
                Button(intent: StopTimerIntent(habitId: context.attributes.habitId)) {
                    Label(context.state.isTimerRunning ? "Pause" : "Resume",
                          systemImage: context.state.isTimerRunning ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.bordered)
                .tint(context.state.isTimerRunning ? .orange : .green)
                
                Spacer()
                
                Button(intent: AddTimeIntent(habitId: context.attributes.habitId)) {
                    Label("+1m", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .tint(.purple)
                
                Button(intent: CompleteHabitIntent(habitId: context.attributes.habitId)) {
                    Label("Done", systemImage: "checkmark")
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            }
        }
        .padding()
    }
}

struct HabitInfoView: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(context.attributes.habitName)
                .font(.caption)
                .fontWeight(.medium)
            Text("Goal: \(context.attributes.habitGoal.formattedAsTime())")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct TimerView: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    
    var body: some View {
        VStack(alignment: .trailing) {
            Text(context.state.formattedTime)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
    }
}

struct ControlsView: View {
    let context: ActivityViewContext<HabitActivityAttributes>
    
    var body: some View {
        HStack {
            Button(intent: StopTimerIntent(habitId: context.attributes.habitId)) {
                Image(systemName: context.state.isTimerRunning ? "pause.fill" : "play.fill")
            }
            .buttonStyle(.bordered)
            .tint(context.state.isTimerRunning ? .orange : .green)
            
            Spacer()
            
            Button(intent: CompleteHabitIntent(habitId: context.attributes.habitId)) {
                Image(systemName: "checkmark")
            }
            .buttonStyle(.bordered)
            .tint(.blue)
        }
    }
}

@main
struct LiveActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitLiveActivityWidget()
    }
}
