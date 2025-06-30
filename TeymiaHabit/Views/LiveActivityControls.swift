import SwiftUI

// MARK: - Live Activity Status Indicator
struct LiveActivityStatusView: View {
    let hasActiveLiveActivity: Bool
    let isTimerRunning: Bool
    
    var body: some View {
        if hasActiveLiveActivity {
            HStack(spacing: 6) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isTimerRunning ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isTimerRunning)
                
                Text("Live Activity Active")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Image(systemName: "iphone")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.green.opacity(0.1))
                    .stroke(.green.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Live Activity Control Button
struct LiveActivityControlButton: View {
    let habit: Habit
    let isTimerRunning: Bool
    let hasActiveLiveActivity: Bool
    let onStartLiveActivity: () async -> Void
    let onEndLiveActivity: () async -> Void
    
    @State private var isLoading = false
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(Date())
    }
    
    var body: some View {
        // Only show for time-based habits on today's date
        if habit.type == .time && isToday {
            Button(action: {
                Task {
                    isLoading = true
                    
                    if hasActiveLiveActivity {
                        await onEndLiveActivity()
                    } else {
                        await onStartLiveActivity()
                    }
                    
                    isLoading = false
                }
            }) {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: hasActiveLiveActivity ? "minus.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(hasActiveLiveActivity ? "Stop Live Activity" : "Start Live Activity")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(hasActiveLiveActivity ? .red.gradient : .blue.gradient)
                )
            }
            .disabled(isLoading)
            .opacity(isLoading ? 0.7 : 1.0)
        }
    }
}

// MARK: - Enhanced Timer Controls with Live Activity
struct TimerControlsWithLiveActivity: View {
    let habit: Habit
    let isTimerRunning: Bool
    let hasActiveLiveActivity: Bool
    let onToggleTimer: () -> Void
    let onStartLiveActivity: () async -> Void
    let onEndLiveActivity: () async -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Main timer toggle button
            Button(action: onToggleTimer) {
                HStack(spacing: 12) {
                    Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .medium))
                    
                    Text(isTimerRunning ? "Pause Timer" : "Start Timer")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isTimerRunning ? .orange.gradient : .green.gradient)
                )
            }
            
            // Live Activity controls
            HStack(spacing: 12) {
                LiveActivityControlButton(
                    habit: habit,
                    isTimerRunning: isTimerRunning,
                    hasActiveLiveActivity: hasActiveLiveActivity,
                    onStartLiveActivity: onStartLiveActivity,
                    onEndLiveActivity: onEndLiveActivity
                )
                
                Spacer()
            }
        }
    }
}

// MARK: - Integration for HabitDetailView

extension View {
    @ViewBuilder
    func liveActivityStatusIfNeeded(
        habit: Habit,
        hasActiveLiveActivity: Bool,
        isTimerRunning: Bool
    ) -> some View {
        VStack(spacing: 8) {
            self
            
            // Show Live Activity status for time habits on today
            if habit.type == .time && Calendar.current.isDateInToday(Date()) {
                LiveActivityStatusView(
                    hasActiveLiveActivity: hasActiveLiveActivity,
                    isTimerRunning: isTimerRunning
                )
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: hasActiveLiveActivity)
            }
        }
    }
}
